// lib/applications/session_management.dart

import 'dart:typed_data';

import '../core/diameter_message.dart';
import '../core/avp_dictionary.dart';
import 'base/capabilities_exchange.dart';

class DiameterSessionManager {
  final Map<String, DiameterSession> sessions = {};

  // Server's identity, needed for responses
  final String originHost;
  final String originRealm;

  DiameterSessionManager({required this.originHost, required this.originRealm});

  /// The main entry point for handling requests on the server.
  DiameterMessage handleRequest(DiameterMessage request) {
    // Route request to the appropriate handler based on the command code
    switch (request.commandCode) {
      case CMD_CAPABILITIES_EXCHANGE:
        // FIX: Pass the request directly without casting
        return _handleCER(request);

      case CMD_CREDIT_CONTROL:
        // For CCR, we need to manage a session
        final sessionIdAvp = request.getAVP(AVP_SESSION_ID);
        if (sessionIdAvp == null) {
          // Return an error: DIAMETER_MISSING_AVP
          return _createErrorResponse(request, 5005);
        }

        final sessionId = String.fromCharCodes(sessionIdAvp.data);
        final session = sessions[sessionId];

        final ccRequestTypeAvp = request.getAVP(AVP_CC_REQUEST_TYPE);
        final ccRequestType = (ccRequestTypeAvp != null)
            ? ByteData.view(ccRequestTypeAvp.data.buffer).getUint32(0)
            : 0;

        if (session == null && ccRequestType == 1) {
          // 1 == INITIAL_REQUEST
          // Create a new session for CCR-Initial
          sessions[sessionId] = DiameterSession(sessionId: sessionId);
          print('New session created: $sessionId');
        } else if (session == null) {
          // No session exists for a CCR-Update/Terminate
          return _createErrorResponse(
            request,
            5002,
          ); // DIAMETER_UNKNOWN_SESSION_ID
        }

        return _handleCCR(request);

      default:
        // Return an error: DIAMETER_COMMAND_UNSUPPORTED
        return _createErrorResponse(request, 3001);
    }
  }

  // FIX: The method now accepts the base DiameterMessage type
  DiameterMessage _handleCER(DiameterMessage cer) {
    return CapabilitiesExchangeAnswer.fromRequest(
      cer, // Pass the generic message
      resultCode: 2001, // DIAMETER_SUCCESS
      originHost: originHost,
      originRealm: originRealm,
      hostIpAddress: '127.0.0.1', // Server's IP
      vendorId: 100,
      productName: 'DartDiameterServerV1',
    );
  }

  DiameterMessage _handleCCR(DiameterMessage ccr) {
    return DiameterMessage.fromFields(
      commandCode: CMD_CREDIT_CONTROL,
      applicationId: APP_ID_CREDIT_CONTROL,
      flags: 0, // This is an Answer
      hopByHopId: ccr.hopByHopId,
      endToEndId: ccr.endToEndId,
      avpList: [
        ccr.getAVP(AVP_SESSION_ID)!,
        AVP.fromUnsigned32(AVP_RESULT_CODE, 2001), // DIAMETER_SUCCESS
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
        ccr.getAVP(AVP_CC_REQUEST_NUMBER)!,
      ],
    );
  }

  DiameterMessage _createErrorResponse(
    DiameterMessage request,
    int resultCode,
  ) {
    return DiameterMessage.fromFields(
      commandCode: request.commandCode,
      applicationId: request.applicationId,
      flags: DiameterMessage.FLAG_ERROR, // Set the Error bit
      hopByHopId: request.hopByHopId,
      endToEndId: request.endToEndId,
      avpList: [
        AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
      ],
    );
  }
}

class DiameterSession {
  final String sessionId;
  DiameterSession({required this.sessionId});
}
