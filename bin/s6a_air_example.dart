import 'dart:convert';
import 'dart:typed_data';
import 'package:diameter_protocol/core/diameter_client2.dart';
// import 'package:diameter_protocol/core/avp_dictionary2.dart';
import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/s6a/s6a.dart';

Future<void> main() async {
  // --- Configuration ---
  final serverHost = '127.0.0.1';
  final serverPort = 3868;
  final clientOriginHost = 'mme.dart.com'; // Simulating an MME
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
      productName: 'DartMME_V1',
    );
    await client.sendRequest(cer);
    print('✅ CER/CEA exchange successful.\n');

    // 2. Send an S6a Authentication-Information-Request (AIR)
    print(
      '--- Step 2: Sending S6a Authentication Information Request (AIR) ---',
    );
    final sessionId =
        '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';
    final air = AuthenticationInformationRequest(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'hss.dart.com',
      imsi: '262011234567890', // Example IMSI
      // visitedPlmnId: utf8.decode([0x62, 0xF1, 0x10]), // Example PLMN ID
      visitedPlmnId: "mtn", // Example PLMN ID
      // imsi: "260972462922",
    );
    final aia = await client.sendRequest(air);
    print('✅ AIR/AIA exchange successful. Authentication vectors received.');
    print('<< Received AIA:\n$aia');
  } catch (e, st) {
    print('❌ An error occurred: $e');
    print("$st");
  } finally {
    client.disconnect();
  }
}
