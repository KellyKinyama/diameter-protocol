// lib/applications/eap/eap.dart

import 'dart:typed_data';
import '../../core/avp_dictionary2.dart';
import '../../core/diameter_message3.dart';

class DiameterEAPRequest extends DiameterMessage {
  DiameterEAPRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required Uint8List eapPayload,
  }) : super.fromFields(
         commandCode: CMD_DIAMETER_EAP,
         applicationId: APP_ID_EAP,
         flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_SESSION_ID, sessionId),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_EAP),
           AVP.fromEnumerated(
             AVP_AUTH_REQUEST_TYPE,
             3,
           ), // AUTHORIZE_AUTHENTICATE
           AVP(code: AVP_EAP_PAYLOAD, data: eapPayload),
         ],
       );
}

class DiameterEAPAnswer extends DiameterMessage {
  DiameterEAPAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
    required Uint8List eapPayload,
  }) : super.fromFields(
         commandCode: CMD_DIAMETER_EAP,
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
           AVP(code: AVP_EAP_PAYLOAD, data: eapPayload),
         ],
       );
}
