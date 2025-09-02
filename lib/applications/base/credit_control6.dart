// lib/applications/credit_control/credit_control4.dart

import '../../core/avp_dictionary.dart';
import '../../core/diameter_avp.dart';
import '../../core/message_generator.dart';
import '../common_3gpp_avps.dart';

class CreditControlRequest extends MessageGenerator {
  String sessionId;
  int requestType;
  int requestNumber;
  String? serviceContextId;
  ServiceInformation? serviceInformation;

  CreditControlRequest.update({
    required this.sessionId,
    required this.requestNumber,
    this.serviceContextId,
    this.serviceInformation,
  }) : requestType = 2; // UPDATE

  @override
  List<AVP> toAVPs() {
    var avps = <AVP>[
      AVP.fromValue(AVP_SESSION_ID, sessionId),
      AVP.fromValue(AVP_CC_REQUEST_TYPE, requestType),
      AVP.fromValue(AVP_CC_REQUEST_NUMBER, requestNumber),
    ];
    if (serviceContextId != null) {
      avps.add(AVP.fromValue(AVP_SERVICE_CONTEXT_ID, serviceContextId!));
    }
    if (serviceInformation != null) {
      avps.add(AVP.fromValue(
        AVP_SERVICE_INFORMATION,
        serviceInformation!.toAVPs(),
        vendorId: VENDOR_ID_3GPP,
      ));
    }
    return avps;
  }
}