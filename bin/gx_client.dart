// bin/gx_client.dart

import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/gx/gx.dart';
import 'package:diameter_protocol/core/avp_dictionary2.dart';
import 'package:diameter_protocol/core/diameter_client2.dart';
import 'package:diameter_protocol/core/diameter_message3.dart';

Future<void> main() async {
  final serverHost = '127.0.0.1';
  final serverPort = 3868;
  final clientOriginHost = 'pcef.dart.com';
  final clientOriginRealm = 'dart.com';

  final client = DiameterClient(
    host: serverHost,
    port: serverPort,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
  );

  try {
    await client.connect();

    // 1. Capabilities Exchange (must advertise support for Gx)
    print('--- Step 1: Performing Capabilities Exchange ---');
    final cer = CapabilitiesExchangeRequest(
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      hostIpAddress: '127.0.0.1',
      vendorId: VENDOR_ID_3GPP,
      productName: 'DartPCEF-Client',
      supportedVendorIds: [VENDOR_ID_3GPP],
      authApplicationIds: [APP_ID_3GPP_GX],
    );
    final cea = await client.sendRequest(cer);
    if (cea?.getAVP(AVP_RESULT_CODE)?.data?.buffer.asByteData().getUint32(0) !=
        DIAMETER_SUCCESS) {
      throw Exception(
        'CER failed. Does server support Gx (AppId ${APP_ID_3GPP_GX}})?',
      );
    }
    print('✅ CER/CEA exchange successful.\n');

    // 2. Request Policy and Charging Rules for a user (IMSI)
    print('--- Step 2: Requesting PCC Rules via Gx (CCR-Initial) ---');
    final sessionId =
        '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';
    final imsi = "123456789012345";

    final gxCcr = GxCreditControlRequest.initial(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      subscriptionId: imsi,
    );

    final gxCca = await client.sendRequest(gxCcr);
    final resultCode = gxCca
        ?.getAVP(AVP_RESULT_CODE)
        ?.data
        ?.buffer
        .asByteData()
        .getUint32(0);

    if (resultCode == DIAMETER_SUCCESS) {
      print('✅ Gx session established successfully!');
      final ruleInstallAvp = gxCca?.getAVP(AVP_CHARGING_RULE_INSTALL);
      if (ruleInstallAvp != null) {
        print('   -> Server installed charging rules:');
        // Decode the grouped AVP to see its contents
        final innerAvps = AVP.decode(ruleInstallAvp.encode()).avps;
        innerAvps?.forEach((avp) {
          print('      - ${avp}');
        });
      } else {
        print('   -> Server did not install any rules in this response.');
      }
    } else {
      print('❌ Gx session establishment failed with Result-Code: $resultCode');
    }
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    client.disconnect();
  }
}
