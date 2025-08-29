// lib/applications/credit_control/credit_control.dart

import '../../core/diameter_message2.dart';
import '../../core/avp_dictionary.dart';

/// Creates Gy Credit-Control-Request (CCR) messages for an Online Charging System.
class CreditControlRequest extends DiameterMessage {
  CreditControlRequest._({
    required int flags,
    required int hopByHopId,
    required int endToEndId,
    required List<AVP> avpList,
  }) : super(
         length:
             20 + avpList.fold(0, (sum, avp) => sum + avp.getPaddedLength()),
         commandCode: CMD_CREDIT_CONTROL,
         applicationId: APP_ID_CREDIT_CONTROL,
         flags: flags,
         hopByHopId: hopByHopId,
         endToEndId: endToEndId,
         version: 1,
         avps: avpList,
       );

  /// Creates a CCR-Initial to reserve service units before a session starts.
  factory CreditControlRequest.initial({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    int requestedOctets = 500000,
  }) {
    // Correctly create the grouped AVP by encoding its inner AVP first.
    final rsuInnerAvp = AVP.fromUnsigned32(
      AVP_CC_TOTAL_OCTETS,
      requestedOctets,
    );
    final rsu = AVP(
      code: AVP_REQUESTED_SERVICE_UNIT,
      data: rsuInnerAvp.encode(),
    );

    return CreditControlRequest._(
      flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
      hopByHopId: DiameterMessage.generateId(),
      endToEndId: DiameterMessage.generateId(),
      avpList: [
        AVP.fromString(AVP_SESSION_ID, sessionId),
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
        AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
        AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_CREDIT_CONTROL),
        AVP.fromEnumerated(AVP_CC_REQUEST_TYPE, 1), // INITIAL_REQUEST
        AVP.fromUnsigned32(AVP_CC_REQUEST_NUMBER, 0),
        rsu,
      ],
    );
  }

  /// Creates a CCR-Update to report usage and request more service units.
  factory CreditControlRequest.update({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required int requestNumber,
    int usedOctets = 500000,
    int requestedOctets = 500000,
  }) {
    final usuInnerAvp = AVP.fromUnsigned32(AVP_CC_TOTAL_OCTETS, usedOctets);
    final usu = AVP(code: AVP_USED_SERVICE_UNIT, data: usuInnerAvp.encode());

    final rsuInnerAvp = AVP.fromUnsigned32(
      AVP_CC_TOTAL_OCTETS,
      requestedOctets,
    );
    final rsu = AVP(
      code: AVP_REQUESTED_SERVICE_UNIT,
      data: rsuInnerAvp.encode(),
    );

    return CreditControlRequest._(
      flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
      hopByHopId: DiameterMessage.generateId(),
      endToEndId: DiameterMessage.generateId(),
      avpList: [
        AVP.fromString(AVP_SESSION_ID, sessionId),
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
        AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
        AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_CREDIT_CONTROL),
        AVP.fromEnumerated(AVP_CC_REQUEST_TYPE, 2), // UPDATE_REQUEST
        AVP.fromUnsigned32(AVP_CC_REQUEST_NUMBER, requestNumber),
        usu,
        rsu,
      ],
    );
  }

  /// Creates a CCR-Terminate to end the session and report final usage.
  factory CreditControlRequest.terminate({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required int requestNumber,
    int finalUsedOctets = 100000,
  }) {
    final usuInnerAvp = AVP.fromUnsigned32(
      AVP_CC_TOTAL_OCTETS,
      finalUsedOctets,
    );
    final usu = AVP(code: AVP_USED_SERVICE_UNIT, data: usuInnerAvp.encode());

    return CreditControlRequest._(
      flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
      hopByHopId: DiameterMessage.generateId(),
      endToEndId: DiameterMessage.generateId(),
      avpList: [
        AVP.fromString(AVP_SESSION_ID, sessionId),
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
        AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
        AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_CREDIT_CONTROL),
        AVP.fromEnumerated(AVP_CC_REQUEST_TYPE, 3), // TERMINATION_REQUEST
        AVP.fromUnsigned32(AVP_CC_REQUEST_NUMBER, requestNumber),
        usu,
        AVP.fromEnumerated(AVP_TERMINATION_CAUSE, 1), // DIAMETER_LOGOUT
      ],
    );
  }
}
