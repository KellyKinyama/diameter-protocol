// lib/core/diameter_server2.dart

import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'diameter_message4.dart';
import '../applications/session_manager2.dart';
import 'avp_dictionary.dart';

enum PeerState { PENDING, OPEN, CLOSED }

class Peer {
  final Socket socket;
  PeerState state = PeerState.PENDING;
  String? originHost;

  Peer(this.socket);
}

class DiameterServer {
  final String host;
  final int port;
  final DiameterSessionManager sessionManager;
  ServerSocket? _serverSocket;
  final Map<String, Peer> peers = HashMap();
  final Map<int, Completer<DiameterMessage>> _pendingServerRequests = HashMap();

  DiameterServer(this.host, this.port, this.sessionManager);

  Future<void> start() async {
    try {
      _serverSocket = await ServerSocket.bind(host, port);
      print('✅ Diameter Server listening on $host:$port');
      _serverSocket!.listen(_handleConnection);
    } catch (e) {
      print('❌ Failed to start Diameter server: $e');
    }
  }

  void _handleConnection(Socket socket) {
    final peer = Peer(socket);
    socket.listen(
      (data) async {
        try {
          final message = DiameterMessage.decode(data);
          print(
            '<< Received Message from ${socket.remoteAddress.address}:\n$message',
          );

          if (message.flags & DiameterMessage.FLAG_REQUEST != 0) {
            final response = await sessionManager.handleRequest(message);

            if (message.commandCode == 257) {
              // CER
              final originHostAvp = message.getAVP(AVP_ORIGIN_HOST);
              if (originHostAvp != null) {
                peer.originHost = originHostAvp.value as String;
                peer.state = PeerState.OPEN;
                peers[peer.originHost!] = peer;
                print('✅ Peer state for ${peer.originHost} is now OPEN.');
              }
            }

            print(
              '>> Sending Response to ${peer.originHost ?? 'unknown'}:\n$response',
            );
            socket.add(response.encode());
          } else {
            // It's an answer
            final completer = _pendingServerRequests.remove(message.hopByHopId);
            completer?.complete(message);
          }
        } catch (e) {
          print('Error processing message: $e');
        }
      },
      onError: (error) {
        if (peer.originHost != null) peers.remove(peer.originHost);
        socket.destroy();
      },
      onDone: () {
        if (peer.originHost != null) peers.remove(peer.originHost);
      },
    );
  }
}
