// lib/applications/credit_control/credit_control.dart

import 'dart:typed_data';
import '../../core/diameter_message2.dart';
import '../../core/avp_dictionary.dart';

/// Creates RFC 4006 compliant Credit-Control-Request (CCR) messages.
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

  /// Creates a CCR with CC-Request-Type set to INITIAL_REQUEST (1).
  factory CreditControlRequest.initial({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required String serviceContextId,
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
        AVP.fromString(AVP_SERVICE_CONTEXT_ID, serviceContextId), // Mandatory
        AVP.fromEnumerated(AVP_CC_REQUEST_TYPE, 1), // INITIAL_REQUEST
        AVP.fromUnsigned32(AVP_CC_REQUEST_NUMBER, 0),
        AVP.fromEnumerated(
          AVP_MULTIPLE_SERVICES_INDICATOR,
          1,
        ), // MULTIPLE_SERVICES_SUPPORTED
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
    final usu = AVP.fromGrouped(AVP_USED_SERVICE_UNIT, [
      AVP.fromUnsigned32(AVP_CC_TOTAL_OCTETS, usedOctets),
    ]);

    final rsu = AVP.fromGrouped(AVP_REQUESTED_SERVICE_UNIT, [
      AVP.fromUnsigned32(AVP_CC_TOTAL_OCTETS, requestedOctets),
    ]);

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
    final usu = AVP.fromGrouped(AVP_USED_SERVICE_UNIT, [
      AVP.fromUnsigned32(AVP_CC_TOTAL_OCTETS, finalUsedOctets),
    ]);

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
