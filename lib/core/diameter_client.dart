// lib/core/diameter_client.dart

import 'dart:async';
import 'dart:io';
import 'diameter_message.dart';

class DiameterClient {
  final String host;
  final int port;
  Socket? _socket;

  DiameterClient(this.host, this.port);

  Future<void> connect() async {
    try {
      _socket = await Socket.connect(host, port);
      print('✅ Connected to Diameter Server at $host:$port');
    } catch (e) {
      print('❌ Failed to connect to Diameter Server: $e');
      rethrow;
    }
  }

  Future<DiameterMessage> sendRequest(DiameterMessage request) async {
    if (_socket == null) {
      throw StateError('Client not connected. Call connect() first.');
    }

    final completer = Completer<DiameterMessage>();
    
    StreamSubscription? subscription;
    subscription = _socket!.listen(
      (data) {
        final response = DiameterMessage.decode(data);
        // Match response using Hop-by-Hop ID
        if (response.hopByHopId == request.hopByHopId) {
          completer.complete(response);
          subscription?.cancel();
        }
      },
      onError: (error) {
        completer.completeError(error);
        subscription?.cancel();
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError('Connection closed before response received.');
        }
      }
    );

    print('>> Sending Request:\n$request');
    _socket!.add(request.encode());

    return completer.future;
  }

  void disconnect() {
    _socket?.destroy();
    print('🔌 Disconnected from Diameter Server.');
  }
}