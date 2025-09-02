// bin/gx_client.dart

import 'package:diameter_protocol/applications/base/capabilities_exchange2.dart';
import 'package:diameter_protocol/applications/gx/gx2.dart';
import 'package:diameter_protocol/core/diameter_client3.dart';
// import 'package:diameter_protocol/core/diameter_message5.dart';

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
    await client.sendRequest(
      commandCode: 257,
      applicationId: 0,
      generator: CapabilitiesExchangeRequest(
        originHost: clientOriginHost,
        originRealm: clientOriginRealm,
        hostIpAddress: '127.0.0.1',
        vendorId: 10415,
        productName: 'DartPCEF-Client',
        supportedVendorIds: [10415],
        authApplicationIds: [16777238], // Gx
      ),
    );
    print('✅ CER/CEA exchange successful.\n');

    // 2. Request Policy and Charging Rules for a user (IMSI)
    print('--- Step 2: Requesting PCC Rules via Gx (CCR-Initial) ---');
    final sessionId =
        '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';
    final imsi = "123456789012345";

    final gxCca = await client.sendRequest(
      commandCode: 272,
      applicationId: 16777238, // Gx
      generator: GxCreditControlRequest(
        sessionId: sessionId,
        subscriptionId: imsi,
      ),
    );

    print('✅ Gx session established successfully!');
    final ruleInstallAvp = gxCca?.getAVP(
      1001,
      vendorId: 10415,
    ); // Charging-Rule-Install
    if (ruleInstallAvp != null) {
      print('   -> Server installed charging rules:');
      print('      - ${ruleInstallAvp.value}');
    } else {
      print('   -> Server did not install any rules in this response.');
    }
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    client.disconnect();
  }
}
