// lib/core/diameter_server.dart

import 'dart:io';
import 'dart:async';
import 'diameter_message.dart';
import '../applications/session_management3.dart';

class DiameterServer {
  final String host;
  final int port;
  final DiameterSessionManager sessionManager;
  ServerSocket? _serverSocket;

  DiameterServer(this.host, this.port, this.sessionManager);

  Future<void> start() async {
    try {
      _serverSocket = await ServerSocket.bind(host, port);
      print('✅ Diameter Server listening on $host:$port');

      _serverSocket!.listen((socket) {
        final clientHost = socket.remoteAddress.address;
        final clientPort = socket.remotePort;
        print('🤝 Client connected: $clientHost:$clientPort');
        _handleConnection(socket);
      });
    } catch (e) {
      print('❌ Failed to start Diameter Server: $e');
      rethrow;
    }
  }

  void _handleConnection(Socket socket) {
    socket.listen(
      (data) {
        try {
          final request = DiameterMessage.decode(data);
          print(
            '<< Received Request from ${socket.remoteAddress.address}:\n$request',
          );

          // Let the session manager handle the logic and create a response
          final response = sessionManager.handleRequest(request);

          print(
            '>> Sending Response to ${socket.remoteAddress.address}:\n$response',
          );
          socket.add(response.encode());
        } catch (e) {
          print('Error processing message: $e');
          // In a real implementation, you might send a Diameter error message
        }
      },
      onError: (error) {
        print('Socket error: $error');
        socket.destroy();
      },
      onDone: () {
        print(
          '👋 Client disconnected: ${socket.remoteAddress.address}:${socket.remotePort}',
        );
      },
    );
  }

  void stop() {
    _serverSocket?.close();
    print('🛑 Diameter Server stopped.');
  }
}
