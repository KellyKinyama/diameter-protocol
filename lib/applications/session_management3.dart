import 'dart:typed_data';

import '../core/diameter_message.dart';
import '../core/avp_dictionary.dart';
import 'base/capabilities_exchange.dart';

class DiameterSessionManager {
  final Map<String, DiameterSession> sessions = {};
  final String originHost;
  final String originRealm;

  // A simple state ID for the server, initialized with the current time
  final int _originStateId = DateTime.now().millisecondsSinceEpoch;

  DiameterSessionManager({required this.originHost, required this.originRealm});

  DiameterMessage handleRequest(DiameterMessage request) {
    switch (request.commandCode) {
      case CMD_CAPABILITIES_EXCHANGE:
        return _handleCER(request);

      case CMD_DEVICE_WATCHDOG:
        return _handleDWR(request);

      case CMD_CREDIT_CONTROL:
        final sessionIdAvp = request.getAVP(AVP_SESSION_ID);
        if (sessionIdAvp == null) {
          return _createErrorResponse(request, 5005);
        }

        final sessionId = String.fromCharCodes(sessionIdAvp.data);
        final session = sessions[sessionId];

        final ccRequestTypeAvp = request.getAVP(AVP_CC_REQUEST_TYPE);
        final ccRequestType = (ccRequestTypeAvp != null)
            ? ByteData.view(ccRequestTypeAvp.data.buffer).getUint32(0)
            : 0;

        if (session == null && ccRequestType == 1) {
          sessions[sessionId] = DiameterSession(sessionId: sessionId);
          print('New session created: $sessionId');
        } else if (session == null) {
          return _createErrorResponse(request, 5002);
        }
        return _handleCCR(request);

      default:
        return _createErrorResponse(request, 3001);
    }
  }

  /// Handles an incoming DWR and returns a DWA.
  DiameterMessage _handleDWR(DiameterMessage dwr) {
    print('ℹ️  Received Device Watchdog Request, sending Answer.');
    return DiameterMessage.fromFields(
      commandCode: CMD_DEVICE_WATCHDOG,
      applicationId: 0,
      flags: 0, // This is an Answer
      hopByHopId: dwr.hopByHopId,
      endToEndId: dwr.endToEndId,
      avpList: [
        AVP.fromUnsigned32(AVP_RESULT_CODE, 2001), // DIAMETER_SUCCESS
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
        // FIX: Added the mandatory Origin-State-Id AVP
        AVP.fromUnsigned32(AVP_ORIGIN_STATE_ID, _originStateId),
      ],
    );
  }

  // No changes to other methods
  DiameterMessage _handleCER(DiameterMessage cer) {
    return CapabilitiesExchangeAnswer.fromRequest(
      cer,
      resultCode: 2001,
      originHost: originHost,
      originRealm: originRealm,
      hostIpAddress: '127.0.0.1',
      vendorId: 100,
      productName: 'DartDiameterServerV1',
    );
  }

  DiameterMessage _handleCCR(DiameterMessage ccr) {
    return DiameterMessage.fromFields(
      commandCode: CMD_CREDIT_CONTROL,
      applicationId: APP_ID_CREDIT_CONTROL,
      flags: 0,
      hopByHopId: ccr.hopByHopId,
      endToEndId: ccr.endToEndId,
      avpList: [
        ccr.getAVP(AVP_SESSION_ID)!,
        AVP.fromUnsigned32(AVP_RESULT_CODE, 2001),
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
      flags: DiameterMessage.FLAG_ERROR,
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

/// Creates a Session-Termination-Request (STR) message.
/// See RFC 6733 Section 8.4.1 for details.
class SessionTerminationRequest extends DiameterMessage {
  SessionTerminationRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required int authApplicationId,
    int terminationCause = 1, // 1 = DIAMETER_LOGOUT
  }) : super(
          length: 20 +
              [
                AVP.fromString(AVP_SESSION_ID, sessionId),
                AVP.fromString(AVP_ORIGIN_HOST, originHost),
                AVP.fromString(AVP_ORIGIN_REALM, originRealm),
                AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
                AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, authApplicationId),
                AVP.fromEnumerated(AVP_TERMINATION_CAUSE, terminationCause),
              ].fold(0, (sum, avp) => sum + avp.getPaddedLength()),
          commandCode: CMD_SESSION_TERMINATION,
          applicationId: authApplicationId,
          flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
          hopByHopId: DiameterMessage.generateId(),
          endToEndId: DiameterMessage.generateId(),
          version: 1,
          avps: [
            AVP.fromString(AVP_SESSION_ID, sessionId),
            AVP.fromString(AVP_ORIGIN_HOST, originHost),
            AVP.fromString(AVP_ORIGIN_REALM, originRealm),
            AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
            AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, authApplicationId),
            AVP.fromEnumerated(AVP_TERMINATION_CAUSE, terminationCause),
          ],
        );
}

/// Creates an Abort-Session-Request (ASR) message.
/// See RFC 6733 Section 8.5.1 for details.
class AbortSessionRequest extends DiameterMessage {
  AbortSessionRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required String destinationHost,
    required int authApplicationId,
  }) : super(
          length: 20 +
              [
                AVP.fromString(AVP_SESSION_ID, sessionId),
                AVP.fromString(AVP_ORIGIN_HOST, originHost),
                AVP.fromString(AVP_ORIGIN_REALM, originRealm),
                AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
                AVP.fromString(AVP_DESTINATION_HOST, destinationHost),
                AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, authApplicationId),
              ].fold(0, (sum, avp) => sum + avp.getPaddedLength()),
          commandCode: CMD_ABORT_SESSION,
          applicationId: authApplicationId,
          flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
          hopByHopId: DiameterMessage.generateId(),
          endToEndId: DiameterMessage.generateId(),
          version: 1,
          avps: [
            AVP.fromString(AVP_SESSION_ID, sessionId),
            AVP.fromString(AVP_ORIGIN_HOST, originHost),
            AVP.fromString(AVP_ORIGIN_REALM, originRealm),
            AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
            AVP.fromString(AVP_DESTINATION_HOST, destinationHost),
            AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, authApplicationId),
          ],
        );
}