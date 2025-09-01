// lib/applications/gx/gx.dart

import '../../core/avp_dictionary2.dart';
import '../../core/diameter_message3.dart';

/// Helper class to build a Charging-Rule-Definition AVP.
class ChargingRuleDefinition {
  final String ruleName;
  final int precedence;
  final int ratingGroup;
  final int qci;

  ChargingRuleDefinition({
    required this.ruleName,
    this.precedence = 100,
    this.ratingGroup = 1,
    this.qci = 9, // Best effort
  });

  AVP toAVP() {
    return AVP.fromGrouped(AVP_CHARGING_RULE_DEFINITION, [
      AVP.fromString(
        AVP_CHARGING_RULE_NAME,
        ruleName,
        vendorId: VENDOR_ID_3GPP,
      ),
      AVP.fromUnsigned32(AVP_PRECEDENCE, precedence, vendorId: VENDOR_ID_3GPP),
      AVP.fromUnsigned32(
        AVP_RATING_GROUP,
        ratingGroup,
        vendorId: VENDOR_ID_3GPP,
      ),
      AVP.fromGrouped(AVP_QOS_INFORMATION, [
        AVP.fromEnumerated(
          AVP_QOS_CLASS_IDENTIFIER,
          qci,
          vendorId: VENDOR_ID_3GPP,
        ),
      ], vendorId: VENDOR_ID_3GPP),
    ], vendorId: VENDOR_ID_3GPP);
  }
}

/// Creates a Gx Credit-Control-Request (CCR) message.
class GxCreditControlRequest extends DiameterMessage {
  GxCreditControlRequest.initial({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required String subscriptionId,
  }) : super.fromFields(
         commandCode: CMD_CREDIT_CONTROL,
         applicationId: APP_ID_3GPP_GX,
         flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_SESSION_ID, sessionId),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_3GPP_GX),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
           AVP.fromUnsigned32(AVP_CC_REQUEST_TYPE, 1), // INITIAL
           AVP.fromUnsigned32(AVP_CC_REQUEST_NUMBER, 0),
           AVP.fromGrouped(AVP_SUBSCRIPTION_ID, [
             AVP.fromEnumerated(AVP_SUBSCRIPTION_ID_TYPE, 1), // END_USER_IMSI
             AVP.fromString(AVP_SUBSCRIPTION_ID_DATA, subscriptionId),
           ]),
           AVP.fromEnumerated(
             AVP_IP_CAN_TYPE,
             0,
             vendorId: VENDOR_ID_3GPP,
           ), // 3GPP-GPRS
         ],
       );
}

/// Creates a Gx Credit-Control-Answer (CCA) message.
class GxCreditControlAnswer extends DiameterMessage {
  GxCreditControlAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
    List<ChargingRuleDefinition>? rulesToInstall,
  }) : super.fromFields(
         commandCode: CMD_CREDIT_CONTROL,
         applicationId: request.applicationId,
         flags: 0, // Answer
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           request.getAVP(AVP_SESSION_ID)!,
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_3GPP_GX),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           request.getAVP(AVP_CC_REQUEST_TYPE)!,
           request.getAVP(AVP_CC_REQUEST_NUMBER)!,
           if (rulesToInstall != null && rulesToInstall.isNotEmpty)
             AVP.fromGrouped(
               AVP_CHARGING_RULE_INSTALL,
               rulesToInstall.map((rule) => rule.toAVP()).toList(),
               vendorId: VENDOR_ID_3GPP,
             ),
         ],
       );
}
