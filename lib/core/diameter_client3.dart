// lib/core/diameter_client.dart

import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'dart:typed_data';
import 'diameter_message.dart';
import '../applications/base/watchdog.dart';
import 'avp_dictionary.dart';

class DiameterClient {
  final String host;
  final int port;
  final String originHost;
  final String originRealm;
  final Duration watchdogInterval;

  Socket? _socket;
  Timer? _watchdogTimer;

  // A map to hold pending requests, keyed by their Hop-by-Hop ID.
  final Map<int, Completer<DiameterMessage>> _pendingRequests = HashMap();

  DiameterClient({
    required this.host,
    required this.port,
    required this.originHost,
    required this.originRealm,
    this.watchdogInterval = const Duration(seconds: 30),
  });

  /// Establishes a connection to the Diameter server and starts the listener.
  Future<void> connect() async {
    try {
      _socket = await Socket.connect(host, port);
      print('✅ Connected to Diameter Server at $host:$port');
      _startListening(); // Start the single, persistent listener.
      _resetWatchdogTimer(); // Start the watchdog timer.
    } catch (e) {
      print('❌ Failed to connect to Diameter Server: $e');
      rethrow;
    }
  }

  /// Sets up a single listener for the entire life of the socket connection.
  void _startListening() {
    _socket?.listen(
      (data) {
        // Reset timer on any incoming traffic from the peer.
        _resetWatchdogTimer();
        final response = DiameterMessage.decode(data);

        // Ignore requests sent from the server in this client implementation.
        if ((response.flags & DiameterMessage.FLAG_REQUEST) != 0) {
          print(
            "⚠️  Received a request from server (not handled in this example): ${response.commandCode}",
          );
          return;
        }

        // Find the completer for this response in our map using its Hop-by-Hop ID.
        final completer = _pendingRequests.remove(response.hopByHopId);

        if (completer != null) {
          // If a matching request is found, complete its Future with the response.
          completer.complete(response);
        } else {
          print(
            '⚠️  Received response for unknown Hop-by-Hop ID: ${response.hopByHopId}',
          );
        }
      },
      onError: (error) {
        print('Socket error: $error');
        // Fail all pending requests if the socket has an error.
        _pendingRequests.forEach((key, completer) {
          completer.completeError(error);
        });
        _pendingRequests.clear();
        _socket?.destroy();
      },
      onDone: () {
        print('🔌 Connection closed by server.');
        _watchdogTimer?.cancel();
        // Fail all pending requests if the connection is closed.
        _pendingRequests.forEach((key, completer) {
          completer.completeError(
            'Connection closed before response received.',
          );
        });
        _pendingRequests.clear();
      },
    );
  }

  /// Resets the watchdog timer. This is called on any inbound or outbound traffic.
  void _resetWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(watchdogInterval, _sendWatchdogRequest);
  }

  /// Sends a Device-Watchdog-Request to check if the peer is still responsive.
  void _sendWatchdogRequest() {
    print('ℹ️  Watchdog timer expired. Sending DWR...');
    final dwr = DeviceWatchdogRequest(
      originHost: originHost,
      originRealm: originRealm,
    );
    sendRequest(dwr)
        .then((dwa) {
          if (dwa != null) {
            final resultCode = dwa.getAVP(AVP_RESULT_CODE);
            if (resultCode != null &&
                ByteData.view(resultCode.data.buffer).getUint32(0) == 2001) {
              print('❤️  Received DWA, peer is responsive.');
            }
          }
        })
        .catchError((e) {
          print('❌ Watchdog failed: $e');
          disconnect();
        });
  }

  /// Sends a Diameter message and optionally waits for a response.
  Future<DiameterMessage?> sendRequest(
    DiameterMessage request, {
    bool waitForResponse = true,
  }) {
    if (_socket == null) {
      throw StateError('Client not connected. Call connect() first.');
    }
    // Reset the watchdog since we are sending traffic.
    _resetWatchdogTimer();

    print('>> Sending Request:\n$request');
    _socket!.add(request.encode());

    // If we don't need to wait for a response (e.g., for DPR), return immediately.
    if (!waitForResponse) {
      return Future.value(null);
    }

    final completer = Completer<DiameterMessage>();
    _pendingRequests[request.hopByHopId] = completer;

    // The Future will be completed by the central listener when a matching response arrives.
    return completer.future;
  }

  /// Closes the connection and cancels the watchdog timer.
  void disconnect() {
    _watchdogTimer?.cancel();
    _socket?.destroy();
  }
}
