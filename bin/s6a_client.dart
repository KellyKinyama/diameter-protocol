// bin/s6a_client.dart

import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/s6a/s6a.dart';
import 'package:diameter_protocol/core/avp_dictionary2.dart';
import 'package:diameter_protocol/core/diameter_client2.dart';

Future<void> main() async {
  final serverHost = '127.0.0.1';
  final serverPort = 3868;
  final clientOriginHost = 'mme.dart.com';
  final clientOriginRealm = 'dart.com';

  final client = DiameterClient(
    host: serverHost,
    port: serverPort,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
  );

  try {
    await client.connect();

    // 1. Capabilities Exchange (must advertise support for S6a)
    print('--- Step 1: Performing Capabilities Exchange ---');
    final cer = CapabilitiesExchangeRequest(
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      hostIpAddress: '127.0.0.1',
      vendorId: VENDOR_ID_3GPP,
      productName: 'DartMME-Client',
      supportedVendorIds: [VENDOR_ID_3GPP],
      authApplicationIds: [APP_ID_3GPP_S6A],
    );
    final cea = await client.sendRequest(cer);
    if (cea?.getAVP(AVP_RESULT_CODE)?.data?.buffer.asByteData().getUint32(0) !=
        DIAMETER_SUCCESS) {
      throw Exception(
        'CER failed. Does server support S6a (AppId ${APP_ID_3GPP_S6A})?',
      );
    }
    print('✅ CER/CEA exchange successful.\n');

    // 2. Perform an Update Location procedure
    print('--- Step 2: Performing S6a Update Location (ULR) ---');
    final sessionId =
        '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';
    final imsi = "999700123456789";

    final ulr = UpdateLocationRequest(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      imsi: imsi,
      visitedPlmnId: "64801",
    );

    final ula = await client.sendRequest(ulr);
    var resultCode = ula
        ?.getAVP(AVP_RESULT_CODE)
        ?.data
        ?.buffer
        .asByteData()
        .getUint32(0);

    if (resultCode == DIAMETER_SUCCESS) {
      print('✅ ULR successful! User subscription data would be here.');
      print(ula);
    } else {
      print('❌ ULR failed with Result-Code: $resultCode');
    }

    // 3. Perform an Authentication Information procedure
    print('\n--- Step 3: Requesting Auth Info (AIR) ---');
    final air = AuthenticationInformationRequest(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      imsi: imsi,
      visitedPlmnId: "64801",
    );

    final aia = await client.sendRequest(air);
    resultCode = aia
        ?.getAVP(AVP_RESULT_CODE)
        ?.data
        ?.buffer
        .asByteData()
        .getUint32(0);

    if (resultCode == DIAMETER_SUCCESS) {
      print('✅ AIR successful! Authentication vectors would be here.');
      print(aia);
    } else {
      print('❌ AIR failed with Result-Code: $resultCode');
    }
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    client.disconnect();
  }
}
