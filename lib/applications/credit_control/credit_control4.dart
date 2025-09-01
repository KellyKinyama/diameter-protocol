// lib/applications/credit_control/credit_control.dart

import '../../core/avp_dictionary2.dart';
import '../../core/diameter_message3.dart';

class CreditControlRequest extends DiameterMessage {
  CreditControlRequest.initial({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required String serviceContextId,
  }) : super.fromFields(
         commandCode: CMD_CREDIT_CONTROL,
         applicationId: APP_ID_CREDIT_CONTROL,
         flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_SESSION_ID, sessionId),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_CREDIT_CONTROL),
           AVP.fromUnsigned32(AVP_CC_REQUEST_TYPE, 1), // INITIAL
           AVP.fromUnsigned32(AVP_CC_REQUEST_NUMBER, 0),
           AVP.fromString(AVP_SERVICE_CONTEXT_ID, serviceContextId),
         ],
       );

  CreditControlRequest.update({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required int requestNumber,
    required int usedOctets,
  }) : super.fromFields(
         commandCode: CMD_CREDIT_CONTROL,
         applicationId: APP_ID_CREDIT_CONTROL,
         flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_SESSION_ID, sessionId),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_CREDIT_CONTROL),
           AVP.fromUnsigned32(AVP_CC_REQUEST_TYPE, 2), // UPDATE
           AVP.fromUnsigned32(AVP_CC_REQUEST_NUMBER, requestNumber),
           AVP.fromGrouped(AVP_USED_SERVICE_UNIT, [
             AVP.fromUnsigned32(AVP_CC_TOTAL_OCTETS, usedOctets),
           ]),
         ],
       );
}

class CreditControlAnswer extends DiameterMessage {
  CreditControlAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
    int grantedUnits = 0,
    bool isFinalUnit = false,
  }) : super.fromFields(
         commandCode: CMD_CREDIT_CONTROL,
         applicationId: request.applicationId,
         flags: 0, // Answer
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           request.getAVP(AVP_SESSION_ID)!,
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           request.getAVP(AVP_CC_REQUEST_TYPE)!,
           request.getAVP(AVP_CC_REQUEST_NUMBER)!,
           AVP.fromGrouped(AVP_GRANTED_SERVICE_UNIT, [
             AVP.fromUnsigned64(AVP_CC_TOTAL_OCTETS, grantedUnits),
           ]),
           if (isFinalUnit)
             AVP.fromGrouped(AVP_FINAL_UNIT_INDICATION, [
               AVP.fromEnumerated(AVP_FINAL_UNIT_ACTION, 0), // TERMINATE
             ]),
         ],
       );
}
