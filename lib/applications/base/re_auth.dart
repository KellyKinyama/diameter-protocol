// lib/applications/base/re_auth.dart

import '../../core/diameter_message.dart';
import '../../core/avp_dictionary3.dart';

class ReAuthRequest extends DiameterMessage {
  ReAuthRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required String destinationHost,
  }) : super(
         length:
             20 +
             [
               AVP.fromString(AVP_SESSION_ID, sessionId),
               AVP.fromString(AVP_ORIGIN_HOST, originHost),
               AVP.fromString(AVP_ORIGIN_REALM, originRealm),
               AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
               AVP.fromString(AVP_DESTINATION_HOST, destinationHost),
               AVP.fromUnsigned32(
                 AVP_AUTH_APPLICATION_ID,
                 APP_ID_CREDIT_CONTROL,
               ),
               AVP.fromEnumerated(AVP_RE_AUTH_REQUEST_TYPE, 0),
             ].fold(0, (sum, avp) => sum + avp.getPaddedLength()),
         commandCode: CMD_RE_AUTH,
         applicationId: APP_ID_CREDIT_CONTROL,
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
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_CREDIT_CONTROL),
           AVP.fromEnumerated(AVP_RE_AUTH_REQUEST_TYPE, 0),
         ],
       );
}

class ReAuthAnswer extends DiameterMessage {
  ReAuthAnswer.fromRequest(
    DiameterMessage rar, {
    required String originHost,
    required String originRealm,
    required int resultCode,
  }) : super(
         length:
             20 +
             [
               rar.getAVP(AVP_SESSION_ID)!,
               AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
               AVP.fromString(AVP_ORIGIN_HOST, originHost),
               AVP.fromString(AVP_ORIGIN_REALM, originRealm),
             ].fold(0, (sum, avp) => sum + avp.getPaddedLength()),
         commandCode: CMD_RE_AUTH,
         applicationId: rar.applicationId,
         flags: 0,
         hopByHopId: rar.hopByHopId,
         endToEndId: rar.endToEndId,
         version: 1,
         avps: [
           rar.getAVP(AVP_SESSION_ID)!,
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
         ],
       );
}
