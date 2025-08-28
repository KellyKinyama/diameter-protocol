// lib/agents/proxy_agent.dart

import '../applications/session_management3.dart';
import '../core/diameter_message.dart';
import '../core/avp_dictionary.dart';
import 'relay_agent.dart'; // Inherits forwarding logic

class ProxyAgent extends RelayAgent {
  ProxyAgent({
    required String host,
    required int port,
    required String nextHopHost,
    required int nextHopPort,
    required DiameterSessionManager sessionManager,
  }) : super(
         host: host,
         port: port,
         nextHopHost: nextHopHost,
         nextHopPort: nextHopPort,
         sessionManager: sessionManager,
       );

  @override
  void _handleConnection(socket) {
    socket.listen((data) async {
      try {
        var request = DiameterMessage.decode(data);
        print('PROXY: Received message, applying policy...');

        // --- POLICY ENFORCEMENT STARTS HERE ---
        // A proxy can inspect and modify AVPs.
        // For example, let's check the username and add a new AVP.
        final userNameAvp = request.getAVP(AVP_USER_NAME);
        if (userNameAvp != null) {
          final userName = String.fromCharCodes(userNameAvp.data);
          print('PROXY: Processing request for user: $userName');

          // Add a new, custom AVP as an example of modification
          request.avps.add(AVP.fromString(999, "Policy-Applied-By-Proxy"));
        }
        // --- POLICY ENFORCEMENT ENDS HERE ---

        // Now, perform the standard relay forwarding logic
        final originalHopByHopId = request.hopByHopId;
        final originHostAvp = request.getAVP(AVP_ORIGIN_HOST);
        if (originHostAvp != null) {
          request.avps.add(
            AVP(code: AVP_ROUTE_RECORD, data: originHostAvp.data),
          );
        }

        var forwardedRequest = DiameterMessage.fromFields(
          commandCode: request.commandCode,
          applicationId: request.applicationId,
          flags: request.flags,
          hopByHopId: DiameterMessage.generateId(),
          endToEndId: request.endToEndId,
          avpList: request.avps,
        );

        final response = await forwardRequest(forwardedRequest);

        final finalResponse = DiameterMessage.fromFields(
          commandCode: response.commandCode,
          applicationId: response.applicationId,
          flags: response.flags,
          hopByHopId: originalHopByHopId,
          endToEndId: response.endToEndId,
          avpList: response.avps,
        );

        socket.add(finalResponse.encode());
      } catch (e) {
        print('Proxy Error: $e');
      }
    });
  }
}
