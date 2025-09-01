
import 'dart:typed_data';
import 'package:diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/core/diameter_message.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control.dart';
import 'package:diameter_protocol/applications/common_avps.dart';

void main() {
  print("--- Building complex CCR from test_credit_control_ps.py ---");

  // Create the main CCR message shell
  final ccr = CreditControlRequest.update(
    sessionId: "sctp-saegwc-poz01.lte.orange.pl;221424325;287370797;65574b0c-2d02",
    originHost: "dra2.gy.mno.net",
    originRealm: "mno.net",
    destinationRealm: "mvno.net",
    requestNumber: 952,
    serviceContextId: "32251@3gpp.org",
  );

  // 1. Create the inner PS-Information grouped AVP
  final psInfo = PsInformation(
    chargingId: Uint8List.fromList([0xff, 0xff, 0xff, 0xff]),
    pdpType: 0, // IPv4
    pdpAddress: "10.0.0.2",
  );

  // 2. Create the outer Service-Information grouped AVP, containing the PsInformation
  final serviceInfo = ServiceInformation(psInformation: psInfo);

  // 3. Add the complete Service-Information AVP to the CCR
  ccr.avps.add(serviceInfo);

  print(ccr);
  print("\nEncoded length: ${ccr.encode().length}");
}
