// lib/applications/nasreq/nasreq.dart

import '../../core/avp_dictionary2.dart';
import '../../core/diameter_message3.dart';

class AARequest extends DiameterMessage {
  AARequest.pap({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required String username,
    required String password,
  }) : super.fromFields(
         commandCode: CMD_AA_REQUEST,
         applicationId: APP_ID_NASREQ,
         flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_SESSION_ID, sessionId),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_NASREQ),
           AVP.fromEnumerated(
             AVP_AUTH_REQUEST_TYPE,
             3,
           ), // AUTHORIZE_AUTHENTICATE
           AVP.fromString(AVP_USER_NAME, username),
           AVP.fromString(AVP_USER_PASSWORD, password),
           AVP.fromEnumerated(AVP_NAS_PORT_TYPE, 5), // Virtual
         ],
       );
}

class AAAnswer extends DiameterMessage {
  AAAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
    String? framedIpAddress,
  }) : super.fromFields(
         commandCode: CMD_AA_REQUEST,
         applicationId: request.applicationId,
         flags: 0, // Answer
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           request.getAVP(AVP_SESSION_ID)!,
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           request.getAVP(AVP_AUTH_REQUEST_TYPE)!,
           if (resultCode == DIAMETER_SUCCESS && framedIpAddress != null)
             AVP.fromAddress(AVP_FRAMED_IP_ADDRESS, framedIpAddress),
         ],
       );
}
