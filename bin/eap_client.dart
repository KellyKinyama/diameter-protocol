// bin/eap_client.dart

import 'dart:typed_data';
import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/eap/eap.dart';
import 'package:diameter_protocol/core/avp_dictionary2.dart';
import 'package:diameter_protocol/core/diameter_client2.dart';

Future<void> main() async {
  final serverHost = '127.0.0.1';
  final serverPort = 3868;
  final clientOriginHost = 'eap.client.dart.com';
  final clientOriginRealm = 'dart.com';

  final client = DiameterClient(
    host: serverHost,
    port: serverPort,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
  );

  try {
    await client.connect();

    // 1. Capabilities Exchange
    print('--- Step 1: Performing Capabilities Exchange ---');
    final cer = CapabilitiesExchangeRequest(
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      hostIpAddress: '127.0.0.1',
      vendorId: 10415,
      productName: 'DartEAP-Client',
    );
    final cea = await client.sendRequest(cer);
    if (cea?.getAVP(AVP_RESULT_CODE)?.data?.buffer.asByteData().getUint32(0) !=
        DIAMETER_SUCCESS) {
      throw Exception('CER failed.');
    }
    print('✅ CER/CEA exchange successful.\n');

    // 2. Start EAP Session
    print('--- Step 2: Starting EAP Session (DER with EAP-Start) ---');
    final sessionId =
        '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';

    // Send an EAP-Start (empty payload)
    var der = DiameterEAPRequest(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      eapPayload: Uint8List(0),
    );

    var dea = await client.sendRequest(der);
    var resultCode = dea
        ?.getAVP(AVP_RESULT_CODE)
        ?.data
        ?.buffer
        .asByteData()
        .getUint32(0);

    if (resultCode != DIAMETER_MULTI_ROUND_AUTH) {
      throw Exception('Expected MULTI_ROUND_AUTH, but got $resultCode');
    }
    print('✅ Received EAP Challenge from server.');

    // 3. Respond to EAP Challenge
    print('\n--- Step 3: Responding to EAP Challenge ---');
    // In a real implementation, we would process the challenge from dea.getAVP(AVP_EAP_PAYLOAD)
    // and generate a valid response. Here we just send dummy data.
    der = DiameterEAPRequest(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      eapPayload: Uint8List.fromList([
        0x02,
        0x02,
        0x00,
        0x08,
        0x04,
        0x0a,
        0x0b,
        0x0c,
      ]),
    ); // Dummy response

    dea = await client.sendRequest(der);
    resultCode = dea
        ?.getAVP(AVP_RESULT_CODE)
        ?.data
        ?.buffer
        .asByteData()
        .getUint32(0);

    if (resultCode == DIAMETER_SUCCESS) {
      print('✅ EAP Authentication successful!');
    } else {
      print('❌ EAP Authentication failed with Result-Code: $resultCode');
    }
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    client.disconnect();
  }
}
