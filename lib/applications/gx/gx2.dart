// lib/applications/gx/gx.dart

import '../../core/avp_dictionary.dart';
import '../../core/diameter_avp.dart';
import '../../core/message_generator.dart';

/// Generator for a 3GPP Charging-Rule-Definition grouped AVP.
class ChargingRuleDefinition extends MessageGenerator {
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

  @override
  List<AVP> toAVPs() {
    // This generates the list of AVPs that go *inside* the
    // Charging-Rule-Definition grouped AVP.
    return [
      AVP.fromValue(1005, ruleName, vendorId: 10415), // Charging-Rule-Name
      AVP.fromValue(1010, precedence, vendorId: 10415), // Precedence
      // Note: Rating-Group is defined in the base RFC, so no vendorId
      AVP.fromValue(432, ratingGroup),
      AVP.fromValue(
        1016, // QoS-Information
        [AVP.fromValue(1028, qci, vendorId: 10415)], // QoS-Class-Identifier
        vendorId: 10415,
      ),
    ];
  }
}

/// Generator for a Gx Credit-Control-Request (CCR) message.
class GxCreditControlRequest extends MessageGenerator {
  String sessionId;
  String subscriptionId; // e.g., an IMSI
  
  GxCreditControlRequest({
    required this.sessionId,
    required this.subscriptionId,
  });

  @override
  List<AVP> toAVPs() {
    return [
      AVP.fromValue(AVP_SESSION_ID, sessionId),
      AVP.fromValue(AVP_CC_REQUEST_TYPE, 1), // INITIAL
      AVP.fromValue(AVP_CC_REQUEST_NUMBER, 0),
      AVP.fromValue(
        AVP_SUBSCRIPTION_ID,
        [
          AVP.fromValue(AVP_SUBSCRIPTION_ID_TYPE, 1), // END_USER_IMSI
          AVP.fromValue(AVP_SUBSCRIPTION_ID_DATA, subscriptionId),
        ],
      ),
      AVP.fromValue(1027, 0, vendorId: 10415), // IP-CAN-Type: 3GPP-GPRS
    ];
  }
}

/// Generator for a Gx Credit-Control-Answer (CCA) message.
class GxCreditControlAnswer extends MessageGenerator {
  List<ChargingRuleDefinition>? rulesToInstall;

  GxCreditControlAnswer({this.rulesToInstall});

  @override
  List<AVP> toAVPs() {
    final avps = <AVP>[];
    if (rulesToInstall != null && rulesToInstall!.isNotEmpty) {
      avps.add(AVP.fromValue(
        1001, // Charging-Rule-Install
        [
          // For each rule definition, create a Charging-Rule-Definition grouped AVP
          ...rulesToInstall!.map((rule) => AVP.fromValue(
                1003, // Charging-Rule-Definition
                rule.toAVPs(), // Get the inner AVPs from the generator
                vendorId: 10415,
              ))
        ],
        vendorId: 10415,
      ));
    }
    return avps;
  }
}