
import 'package:diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/core/diameter_message.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control.dart';
import 'package:diameter_protocol/applications/common_3gpp_avps.dart';

void main() {
  print("--- Building complex CCR with IMS-Information (from test_credit_control_ims.py) ---");

  // 1. Create the innermost grouped AVPs first
  final eventType = EventType(sipMethod: "INVITE", event: "reg");
  final timeStamps = TimeStamps(
    sipRequestTimestamp: DateTime.now(),
    sipResponseTimestamp: DateTime.now(),
  );

  // 2. Create the IMS-Information AVP that contains them
  final imsInfo = ImsInformation(
    eventType: eventType,
    timeStamps: timeStamps,
    callingPartyAddress: "41780000000",
  );

  // 3. Create the top-level Service-Information AVP
  final serviceInfo = ServiceInformation(imsInformation: imsInfo);

  // 4. Create the main CCR message
  final ccr = CreditControlRequest.update(
    sessionId: "sctp-saegwc-poz01.lte.orange.pl;221424325;287370797;65574b0c-2d02",
    originHost: "dra2.gy.mno.net",
    originRealm: "mno.net",
    destinationRealm: "mvno.net",
    requestNumber: 952,
    serviceContextId: "32251@3gpp.org",
  );

  // 5. Add the complex Service-Information AVP to the message
  ccr.avps.add(serviceInfo);

  print(ccr);
  print("\nEncoded length: ${ccr.encode().length}");
}