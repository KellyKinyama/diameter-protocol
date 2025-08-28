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
  Socket? _socket;
  Timer? _watchdogTimer;
  final Duration watchdogInterval;

  final Map<int, Completer<DiameterMessage>> _pendingRequests = HashMap();

  DiameterClient({
    required this.host,
    required this.port,
    required this.originHost,
    required this.originRealm,
    this.watchdogInterval = const Duration(seconds: 30),
  });

  Future<void> connect() async {
    try {
      _socket = await Socket.connect(host, port);
      print('✅ Connected to Diameter Server at $host:$port');
      _startListening();
      _resetWatchdogTimer(); // Start the watchdog
    } catch (e) {
      print('❌ Failed to connect to Diameter Server: $e');
      rethrow;
    }
  }

  void _resetWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(watchdogInterval, _sendWatchdogRequest);
  }

  void _sendWatchdogRequest() {
    print('ℹ️ Watchdog timer expired. Sending DWR...');
    final dwr = DeviceWatchdogRequest(
      originHost: originHost,
      originRealm: originRealm,
    );
    sendRequest(dwr)
        .then((dwa) {
          final resultCode = dwa.getAVP(AVP_RESULT_CODE);
          if (resultCode != null &&
              ByteData.view(resultCode.data.buffer).getUint32(0) == 2001) {
            print('❤️ Received DWA, peer is responsive.');
          }
        })
        .catchError((e) {
          print('❌ Watchdog failed: $e');
          disconnect();
        });
  }

  void _startListening() {
    _socket?.listen(
      (data) {
        _resetWatchdogTimer(); // Reset timer on any incoming traffic
        final response = DiameterMessage.decode(data);

        if ((response.flags & DiameterMessage.FLAG_REQUEST) != 0) {
          print(
            "⚠️ Received a request from server (not handled in this example): ${response.commandCode}",
          );
          return;
        }

        final completer = _pendingRequests.remove(response.hopByHopId);
        if (completer != null) {
          completer.complete(response);
        } else {
          print(
            '⚠️ Received response for unknown Hop-by-Hop ID: ${response.hopByHopId}',
          );
        }
      },
      onError: (error) {
        print('Socket error: $error');
        _pendingRequests.forEach(
          (key, completer) => completer.completeError(error),
        );
        _pendingRequests.clear();
        _socket?.destroy();
      },
      onDone: () {
        print('🔌 Connection closed by server.');
        _watchdogTimer?.cancel();
        _pendingRequests.forEach(
          (key, completer) => completer.completeError('Connection closed'),
        );
        _pendingRequests.clear();
      },
    );
  }

  Future<DiameterMessage> sendRequest(DiameterMessage request) {
    if (_socket == null) {
      throw StateError('Client not connected. Call connect() first.');
    }
    _resetWatchdogTimer(); // Reset timer on any outgoing traffic
    final completer = Completer<DiameterMessage>();
    _pendingRequests[request.hopByHopId] = completer;
    print('>> Sending Request:\n$request');
    _socket!.add(request.encode());
    return completer.future;
  }

  void disconnect() {
    _watchdogTimer?.cancel();
    _socket?.destroy();
  }
}
