// bin/s6a_client.dart

import 'package:diameter_protocol/applications/base/capabilities_exchange2.dart';
import 'package:diameter_protocol/applications/s6a/s6a2.dart';
// import 'package:diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/core/diameter_client3.dart';
import 'package:diameter_protocol/core/diameter_message4.dart';

Future<void> main() async {
  final serverHost = '127.0.0.1';
  final serverPort = 3868;
  final clientOriginHost = 'mme.dart.com';
  final clientOriginRealm = 'dart.com';
  final sessionId =
      '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';
  final imsi = "999700123456789";

  final client = DiameterClient(
    host: serverHost,
    port: serverPort,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
  );

  try {
    await client.connect();

    // 1. Capabilities Exchange
    final cerGenerator = CapabilitiesExchangeRequest(
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      hostIpAddress: '127.0.0.1',
      vendorId: 10415,
      productName: 'DartMME-Client',
      supportedVendorIds: [10415],
      authApplicationIds: [16777251], // S6a
    );
    // final cerMessage = DiameterMessage(
    //   commandCode: 257,
    //   applicationId: 0,
    //   flags: DiameterMessage.FLAG_REQUEST,
    //   hopByHopId: DiameterMessage.generateId(),
    //   endToEndId: DiameterMessage.generateId(),
    //   generator: cerGenerator,
    // );
    await client.sendRequest(
      commandCode: 257,
      applicationId: 0,
      generator: cerGenerator,
    );
    print('✅ CER/CEA exchange successful.\n');

    // 2. Perform an Update Location procedure
    print('--- Step 2: Performing S6a Update Location (ULR) ---');
    final ulrGenerator = UpdateLocationRequest(
      sessionId: sessionId,
      // originHost: clientOriginHost,
      // originRealm: clientOriginRealm,
      // destinationRealm: 'dart.com',
      // imsi: imsi,
      userName: imsi,
      visitedPlmnId: "64801",
    );

    // final ulrMessage = DiameterMessage(
    //   commandCode: 316,
    //   applicationId: 16777251,
    //   flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
    //   hopByHopId: DiameterMessage.generateId(),
    //   endToEndId: DiameterMessage.generateId(),
    //   generator: ulrGenerator,
    // );
    final ula = await client.sendRequest(
      commandCode: 316,
      applicationId: 16777251,
      generator: ulrGenerator,
    );
    print('✅ ULR successful!');
    print(ula);
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    client.disconnect();
  }
}
