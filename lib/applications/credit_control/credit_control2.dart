// lib/applications/credit_control/credit_control.dart

import '../../core/diameter_message2.dart';
import '../../core/avp_dictionary3.dart';

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
        AVP.fromEnumerated(AVP_CC_REQUEST_TYPE, 1),
        AVP.fromUnsigned32(AVP_CC_REQUEST_NUMBER, 0),
        if (userName != null) AVP.fromString(AVP_USER_NAME, userName),
      ],
    );
  }

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
        AVP.fromEnumerated(AVP_CC_REQUEST_TYPE, 3),
        AVP.fromUnsigned32(AVP_CC_REQUEST_NUMBER, requestNumber),
        AVP.fromEnumerated(AVP_TERMINATION_CAUSE, 1),
      ],
    );
  }
}
