// lib/applications/credit_control/credit_control.dart

import '../../core/diameter_message.dart';
import '../../core/avp_dictionary.dart'; // <-- ADD THIS LINE

/// Creates Credit-Control-Request (CCR) messages.
/// See RFC 4006 for details.
class CreditControlRequest extends DiameterMessage {
  // Private constructor now calls the generative super() constructor
  CreditControlRequest._({
    required int flags,
    required int hopByHopId,
    required int endToEndId,
    required List<AVP> avpList,
  }) : super(
         // Calculate length here before calling super()
         length:
             20 + avpList.fold(0, (sum, avp) => sum + avp.getPaddedLength()),
         commandCode: CMD_CREDIT_CONTROL,
         applicationId: APP_ID_CREDIT_CONTROL,
         flags: flags,
         hopByHopId: hopByHopId,
         endToEndId: endToEndId,
         avps: avpList,
         version: 1,
       );

  /// Creates a CCR with CC-Request-Type set to INITIAL_REQUEST (1).
  factory CreditControlRequest.initial({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    String? userName,
  }) {
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
        if (userName != null) AVP.fromString(AVP_USER_NAME, userName),
      ],
    );
  }

  /// Creates a CCR with CC-Request-Type set to TERMINATION_REQUEST (3).
  factory CreditControlRequest.terminate({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required int requestNumber,
  }) {
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
        AVP.fromEnumerated(AVP_TERMINATION_CAUSE, 1), // DIAMETER_LOGOUT
      ],
    );
  }
}
