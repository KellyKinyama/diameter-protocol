// lib/agents/relay_agent.dart

import 'dart:io';

import '../applications/session_management.dart';

import '../core/diameter_message.dart';
import '../core/avp_dictionary.dart';
import '../core/diameter_server.dart';

class RelayAgent extends DiameterServer {
  final String nextHopHost;
  final int nextHopPort;

  RelayAgent({
    required String host,
    required int port,
    required this.nextHopHost,
    required this.nextHopPort,
    required DiameterSessionManager sessionManager,
  }) : super(host, port, sessionManager);

  @override
  void _handleConnection(socket) {
    socket.listen((data) async {
      try {
        var request = DiameterMessage.decode(data);
        print(
          'RELAY: Received message, forwarding to $nextHopHost:$nextHopPort',
        );

        // 1. Save original Hop-by-Hop ID
        final originalHopByHopId = request.hopByHopId;

        // 2. Add Route-Record AVP
        final originHostAvp = request.getAVP(AVP_ORIGIN_HOST);
        if (originHostAvp != null) {
          request.avps.add(
            AVP(code: AVP_ROUTE_RECORD, data: originHostAvp.data),
          );
        }

        // 3. Create a new message with a new Hop-by-Hop ID
        var forwardedRequest = DiameterMessage.fromFields(
          commandCode: request.commandCode,
          applicationId: request.applicationId,
          flags: request.flags,
          hopByHopId: DiameterMessage.generateId(), // New Hop-by-Hop
          endToEndId: request.endToEndId, // Unchanged
          avpList: request.avps,
        );

        // 4. Forward the message and await response
        final response = await forwardRequest(forwardedRequest);

        // 5. Create the final response, restoring original Hop-by-Hop ID
        final finalResponse = DiameterMessage.fromFields(
          commandCode: response.commandCode,
          applicationId: response.applicationId,
          flags: response.flags,
          hopByHopId: originalHopByHopId, // Restore original Hop-by-Hop
          endToEndId: response.endToEndId,
          avpList: response.avps,
        );

        socket.add(finalResponse.encode());
      } catch (e) {
        print('Relay Error: $e');
      }
    });
  }

  Future<DiameterMessage> forwardRequest(DiameterMessage request) async {
    final forwardSocket = await Socket.connect(nextHopHost, nextHopPort);
    forwardSocket.add(request.encode());
    final responseData = await forwardSocket.first;
    forwardSocket.destroy();
    return DiameterMessage.decode(responseData);
  }
}
