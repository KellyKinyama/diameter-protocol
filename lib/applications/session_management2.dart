// lib/applications/session_management.dart

import 'dart:typed_data'; // Import for Uint8List
import '../core/diameter_message.dart';
import '../core/avp_dictionary.dart';
import 'base/capabilities_exchange.dart';
// import '../credit_control/capabilities_exchange.dart';

class DiameterSessionManager {
  final Map<String, DiameterSession> sessions = {};
  final String originHost;
  final String originRealm;
  final int _originStateId = DateTime.now().millisecondsSinceEpoch;

  DiameterSessionManager({required this.originHost, required this.originRealm});

  DiameterMessage handleRequest(DiameterMessage request) {
    switch (request.commandCode) {
      case CMD_CAPABILITIES_EXCHANGE:
        return _handleCER(request);

      case CMD_DEVICE_WATCHDOG:
        return _handleDWR(request);

      case CMD_SESSION_TERMINATION:
        return _handleSTR(request);

      case CMD_ACCOUNTING:
        return _handleACR(request);

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

  /// Handles an incoming CCR and returns a CCA for the Gy interface.
  DiameterMessage _handleCCR(DiameterMessage ccr) {
    final sessionId = String.fromCharCodes(ccr.getAVP(AVP_SESSION_ID)!.data);
    final requestNumber = ByteData.view(
      ccr.getAVP(AVP_CC_REQUEST_NUMBER)!.data.buffer,
    ).getUint32(0);
    print(
      'Gy: Received CCR for session $sessionId (Request Number: $requestNumber)',
    );

    // FIX: Explicitly create a Uint8List for the grouped AVP data
    final gsuData = Uint8List.fromList(
      [
        AVP.fromUnsigned32(AVP_CC_TOTAL_OCTETS, 1000000).encode(),
      ].expand((x) => x).toList(),
    );

    final gsu = AVP(code: AVP_GRANTED_SERVICE_UNIT, data: gsuData);

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
        gsu, // Add the correctly typed Granted-Service-Unit AVP
      ],
    );
  }

  // ... (rest of the file is unchanged)
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

  DiameterMessage _handleDWR(DiameterMessage dwr) {
    print('ℹ️  Received Device Watchdog Request, sending Answer.');
    return DiameterMessage.fromFields(
      commandCode: CMD_DEVICE_WATCHDOG,
      applicationId: 0,
      flags: 0,
      hopByHopId: dwr.hopByHopId,
      endToEndId: dwr.endToEndId,
      avpList: [
        AVP.fromUnsigned32(AVP_RESULT_CODE, 2001),
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
        AVP.fromUnsigned32(AVP_ORIGIN_STATE_ID, _originStateId),
      ],
    );
  }

  DiameterMessage _handleACR(DiameterMessage acr) {
    final recordType = ByteData.view(
      acr.getAVP(AVP_ACCOUNTING_RECORD_TYPE)!.data.buffer,
    ).getUint32(0);
    final sessionId = String.fromCharCodes(acr.getAVP(AVP_SESSION_ID)!.data);
    print(
      '🧾 Received Accounting Request for session $sessionId (Type: $recordType)',
    );

    return DiameterMessage.fromFields(
      commandCode: CMD_ACCOUNTING,
      applicationId: acr.applicationId,
      flags: 0,
      hopByHopId: acr.hopByHopId,
      endToEndId: acr.endToEndId,
      avpList: [
        acr.getAVP(AVP_SESSION_ID)!,
        AVP.fromUnsigned32(AVP_RESULT_CODE, 2001),
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
        acr.getAVP(AVP_ACCOUNTING_RECORD_TYPE)!,
        acr.getAVP(AVP_ACCOUNTING_RECORD_NUMBER)!,
        AVP.fromUnsigned32(AVP_ORIGIN_STATE_ID, _originStateId),
      ],
    );
  }

  DiameterMessage _handleSTR(DiameterMessage str) {
    final sessionId = String.fromCharCodes(str.getAVP(AVP_SESSION_ID)!.data);
    if (sessions.containsKey(sessionId)) {
      sessions.remove(sessionId);
      print('✅ Session terminated and removed: $sessionId');
    } else {
      print('⚠️  Received STR for unknown session: $sessionId');
    }

    return DiameterMessage.fromFields(
      commandCode: CMD_SESSION_TERMINATION,
      applicationId: str.applicationId,
      flags: 0,
      hopByHopId: str.hopByHopId,
      endToEndId: str.endToEndId,
      avpList: [
        AVP.fromString(AVP_SESSION_ID, sessionId),
        AVP.fromUnsigned32(AVP_RESULT_CODE, 2001),
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
        AVP.fromUnsigned32(AVP_ORIGIN_STATE_ID, _originStateId),
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
         length:
             20 +
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

class DiameterSession {
  final String sessionId;
  DiameterSession({required this.sessionId});
}
