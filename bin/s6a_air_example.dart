
import 'dart:typed_data';
import 'package:diameter_protocol/core/diameter_client.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';
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
    print('--- Step 2: Sending S6a Authentication Information Request (AIR) ---');
    final sessionId = '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';
    final air = AuthenticationInformationRequest(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'hss.dart.com',
      userName: '262011234567890', // Example IMSI
      visitedPlmnId: [0x62, 0xF1, 0x10], // Example PLMN ID
    );
    final aia = await client.sendRequest(air);
    print('✅ AIR/AIA exchange successful. Authentication vectors received.');
    print('<< Received AIA:\n$aia');

  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    client.disconnect();
  }
}
