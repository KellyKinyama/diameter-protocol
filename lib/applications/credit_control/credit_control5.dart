// lib/applications/credit_control/credit_control.dart

import '../../core/avp_dictionary.dart';
import '../../core/diameter_avp.dart';
import '../../core/message_generator.dart';

class CreditControlRequest extends MessageGenerator {
  String sessionId;
  int requestType;
  int requestNumber;
  int? usedOctets;

  CreditControlRequest({
    required this.sessionId,
    required this.requestType,
    required this.requestNumber,
    this.usedOctets,
  });

  @override
  List<AVP> toAVPs() {
    var avps = <AVP>[
      AVP.fromValue(AVP_SESSION_ID, sessionId),
      AVP.fromValue(AVP_CC_REQUEST_TYPE, requestType),
      AVP.fromValue(AVP_CC_REQUEST_NUMBER, requestNumber),
    ];
    if (usedOctets != null) {
      avps.add(
        AVP.fromValue(AVP_USED_SERVICE_UNIT, [
          AVP.fromValue(AVP_CC_TOTAL_OCTETS, usedOctets!),
        ]),
      );
    }
    return avps;
  }
}

class CreditControlAnswer extends MessageGenerator {
  String sessionId;
  int requestType;
  int requestNumber;
  int? grantedUnits;
  bool isFinalUnit;

  CreditControlAnswer({
    required this.sessionId,
    required this.requestType,
    required this.requestNumber,
    this.grantedUnits,
    this.isFinalUnit = false,
  });

  @override
  List<AVP> toAVPs() {
    var avps = <AVP>[
      AVP.fromValue(AVP_SESSION_ID, sessionId),
      AVP.fromValue(AVP_CC_REQUEST_TYPE, requestType),
      AVP.fromValue(AVP_CC_REQUEST_NUMBER, requestNumber),
    ];
    if (grantedUnits != null) {
      avps.add(
        AVP.fromValue(AVP_GRANTED_SERVICE_UNIT, [
          AVP.fromValue(AVP_CC_TOTAL_OCTETS, grantedUnits!),
        ]),
      );
    }
    if (isFinalUnit) {
      avps.add(
        AVP.fromValue(
          AVP_FINAL_UNIT_INDICATION,
          [AVP.fromValue(AVP_FINAL_UNIT_ACTION, 0)], // TERMINATE
        ),
      );
    }
    return avps;
  }
}
