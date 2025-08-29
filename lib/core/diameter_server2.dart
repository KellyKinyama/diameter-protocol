// lib/core/diameter_server.dart

import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'diameter_message2.dart';
import '../applications/session_management.dart';
import 'avp_dictionary.dart';
import '../applications/base/capabilities_exchange.dart';

/// Represents the state of a connection with a peer.
enum PeerState { PENDING, OPEN, CLOSED }

/// Holds the state and socket for a single connected peer.
class Peer {
  final Socket socket;
  PeerState state = PeerState.PENDING;
  String? originHost; // The Diameter Identity of the peer.

  Peer(this.socket);
}

class DiameterServer {
  final String host;
  final int port;
  final DiameterSessionManager sessionManager;
  ServerSocket? _serverSocket;

  // Manages connected peers. Key is the peer's Origin-Host.
  final Map<String, Peer> peers = HashMap();
  // Manages requests initiated by this server.
  final Map<int, Completer<DiameterMessage>> _pendingServerRequests = HashMap();

  DiameterServer(this.host, this.port, this.sessionManager);

  /// Binds the server socket and starts listening for incoming peer connections.
  Future<void> start() async {
    try {
      _serverSocket = await ServerSocket.bind(host, port);
      print('✅ Diameter Server listening on $host:$port');

      _serverSocket!.listen((socket) {
        final peerKey = '${socket.remoteAddress.address}:${socket.remotePort}';
        print('🤝 Peer connected: $peerKey');
        final peer = Peer(socket);
        // Initially, we don't know the peer's Origin-Host, so we can't add it to the main map yet.
        _handleConnection(peer);
      });
    } catch (e) {
      print('❌ Failed to start Diameter Server: $e');
      rethrow;
    }
  }

  /// Handles the lifecycle of a single peer connection.
  void _handleConnection(Peer peer) {
    peer.socket.listen(
      (data) {
        try {
          final message = DiameterMessage.decode(data);
          print('<< Received Message from ${peer.socket.remoteAddress.address}:\n$message');
          
          // --- Main State Machine and Dispatch Logic ---
          if ((message.flags & DiameterMessage.FLAG_REQUEST) != 0) {
            // --- Message is a Request from the peer ---
            DiameterMessage response;
            if (peer.state == PeerState.PENDING) {
              if (message.commandCode == CMD_CAPABILITIES_EXCHANGE) {
                response = sessionManager.handleRequest(message);
                final resultCodeAvp = response.getAVP(AVP_RESULT_CODE);
                if (resultCodeAvp != null && ByteData.view(resultCodeAvp.data!.buffer).getUint32(0) == DIAMETER_SUCCESS) {
                  peer.state = PeerState.OPEN;
                  peer.originHost = String.fromCharCodes(message.getAVP(AVP_ORIGIN_HOST)!.data!.toList());
                  peers[peer.originHost!] = peer; // Add peer to the main map, identified by its Origin-Host
                  print('✅ Peer state for ${peer.originHost} is now OPEN.');
                }
              } else {
                response = sessionManager.createErrorResponse(message, 3010); // DIAMETER_UNKNOWN_PEER
              }
            } else if (peer.state == PeerState.OPEN) {
              if (message.commandCode == CMD_CAPABILITIES_EXCHANGE) {
                print("⚠️  Received unexpected CER from an already OPEN peer. Rejecting.");
                response = CapabilitiesExchangeAnswer.fromRequest(
                  message, resultCode: 5012, // DIAMETER_UNABLE_TO_COMPLY
                  originHost: sessionManager.originHost, originRealm: sessionManager.originRealm,
                  hostIpAddress: '127.0.0.1', vendorId: 100, productName: 'DartDiameterServerV1',
                );
              } else {
                response = sessionManager.handleRequest(message);
              }
            } else { // Peer is CLOSED or in an invalid state
              return; 
            }
            print('>> Sending Response to ${peer.originHost ?? 'pending peer'}:\n$response');
            peer.socket.add(response.encode());

          } else {
            // --- Message is an Answer to a server-initiated request ---
            final completer = _pendingServerRequests.remove(message.hopByHopId);
            if (completer != null) {
              completer.complete(message);
            } else {
              print('⚠️  Received answer for unknown server-initiated request: ${message.hopByHopId}');
            }
          }
        } catch (e) {
          print('Error processing message: $e');
        }
      },
      onError: (error) {
        print('Socket error with peer ${peer.originHost}: $error');
        if (peer.originHost != null) peers.remove(peer.originHost);
        peer.socket.destroy();
      },
      onDone: () {
        print('👋 Peer disconnected: ${peer.originHost ?? peer.socket.remoteAddress.address}');
        if (peer.originHost != null) peers.remove(peer.originHost);
      },
    );
  }

  /// Sends a server-initiated request to a specific, connected peer.
  Future<DiameterMessage?> sendRequest(String destinationHost, DiameterMessage request) {
    final peer = peers[destinationHost];
    if (peer == null || peer.state != PeerState.OPEN) {
      throw Exception('Peer $destinationHost is not connected or not in OPEN state.');
    }
    
    print(">> Sending Server-Initiated Request to $destinationHost:\n$request");
    peer.socket.add(request.encode());

    final completer = Completer<DiameterMessage>();
    _pendingServerRequests[request.hopByHopId] = completer;
    return completer.future;
  }

  void stop() {
    _serverSocket?.close();
    peers.forEach((key, peer) => peer.socket.destroy());
    print('🛑 Diameter Server stopped.');
  }
}