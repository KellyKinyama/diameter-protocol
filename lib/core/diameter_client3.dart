// lib/core/diameter_client2.dart

import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'avp_dictionary.dart';
import 'diameter_avp.dart';
import 'diameter_message4.dart';
import 'message_generator.dart';
import '../applications/base/watchdog3.dart';

class DiameterClient {
  final String host;
  final int port;
  final String originHost;
  final String originRealm;
  final Duration watchdogInterval;

  Socket? _socket;
  Timer? _watchdogTimer;
  final Map<int, Completer<DiameterMessage>> _pendingRequests = HashMap();

  DiameterClient({
    required this.host,
    required this.port,
    required this.originHost,
    required this.originRealm,
    this.watchdogInterval = const Duration(seconds: 30),
  });

  /// Establishes a connection to the Diameter server.
  Future<void> connect() async {
    try {
      _socket = await Socket.connect(host, port);
      print('✅ Connected to Diameter Server at $host:$port');
      _startListening();
      _resetWatchdogTimer();
    } catch (e) {
      print('❌ Failed to connect: $e');
      rethrow;
    }
  }

  /// Closes the connection.
  void disconnect() {
    _watchdogTimer?.cancel();
    _socket?.destroy();
    _socket = null;
    print("🔌 Client disconnected.");
  }

  /// Starts the single, persistent listener for incoming messages.
  void _startListening() {
    _socket?.listen(
      (data) {
        try {
          final message = DiameterMessage.decode(data);
          if (message.flags & DiameterMessage.FLAG_REQUEST != 0) {
            // Handle server-initiated requests if needed in the future
            print('<< Received Server-Initiated Request:\n$message');
          } else {
            // It's an answer, find the pending request and complete it.
            final completer = _pendingRequests.remove(message.hopByHopId);
            if (completer != null) {
              completer.complete(message);
            } else {
              print(
                '⚠️  Received answer for unknown Hop-by-Hop ID: ${message.hopByHopId}',
              );
            }
          }
        } catch (e) {
          print('Error processing received message: $e');
        }
      },
      onError: (error) {
        print('Socket error: $error');
        disconnect();
      },
      onDone: () {
        print('🔌 Connection closed by server.');
        disconnect();
      },
    );
  }

  void _resetWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(watchdogInterval, (_) => _sendWatchdog());
  }

  void _sendWatchdog() {
    print('ℹ️  Watchdog timer expired. Sending DWR...');
    sendRequest(
          commandCode: 280, // Device-Watchdog
          applicationId: 0,
          generator: DeviceWatchdogRequest(),
        )
        .then((dwa) {
          if (dwa != null) {
            final resultCode = dwa.getAVP(AVP_RESULT_CODE)?.value as int?;
            if (resultCode == 2001) {
              print('❤️  Received DWA, peer is responsive.');
            }
          }
        })
        .catchError((e) {
          print('❌ Watchdog failed: $e');
          disconnect();
        });
  }

  /// Sends a Diameter message constructed from a generator.
  Future<DiameterMessage?> sendRequest({
    required int commandCode,
    required int applicationId,
    required MessageGenerator generator,
    bool isProxyable = true,
    bool waitForResponse = true,
  }) {
    if (_socket == null) {
      throw StateError('Client not connected. Call connect() first.');
    }
    _resetWatchdogTimer();

    final message = DiameterMessage(
      commandCode: commandCode,
      applicationId: applicationId,
      flags:
          DiameterMessage.FLAG_REQUEST |
          (isProxyable ? DiameterMessage.FLAG_PROXYABLE : 0),
      hopByHopId: DiameterMessage.generateId(),
      endToEndId: DiameterMessage.generateId(),
      generator: generator,
    );

    print('>> Sending Request:\n$message');
    _socket!.add(message.encode());

    if (!waitForResponse) {
      return Future.value(null);
    }

    final completer = Completer<DiameterMessage>();
    _pendingRequests[message.hopByHopId] = completer;
    return completer.future;
  }
}
