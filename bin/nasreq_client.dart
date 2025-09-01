// bin/nasreq_client.dart

import 'dart:typed_data';
import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/nasreq/nasreq.dart';
import 'package:diameter_protocol/core/avp_dictionary2.dart';
import 'package:diameter_protocol/core/diameter_client2.dart';

Future<void> main() async {
  final serverHost = '127.0.0.1';
  final serverPort = 3868;
  final clientOriginHost = 'nas.dart.com';
  final clientOriginRealm = 'dart.com';

  final client = DiameterClient(
    host: serverHost,
    port: serverPort,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
  );

  try {
    await client.connect();

    // 1. Capabilities Exchange (Same as other clients)
    print('--- Step 1: Performing Capabilities Exchange ---');
    final cer = CapabilitiesExchangeRequest(
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      hostIpAddress: '127.0.0.1',
      vendorId: 10415,
      productName: 'DartNAS-Client',
    );
    final cea = await client.sendRequest(cer);
    if (cea?.getAVP(AVP_RESULT_CODE)?.data?.buffer.asByteData().getUint32(0) !=
        DIAMETER_SUCCESS) {
      throw Exception('CER failed.');
    }
    print('✅ CER/CEA exchange successful.\n');

    // 2. Authenticate and Authorize a user using PAP
    print('--- Step 2: Authenticating user via NASREQ (AAR) ---');
    final sessionId =
        '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';
    final aar = AARequest.pap(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      username: 'user@dart.com',
      password: 'password123',
    );
    final aaa = await client.sendRequest(aar);
    final resultCode = aaa
        ?.getAVP(AVP_RESULT_CODE)
        ?.data
        ?.buffer
        .asByteData()
        .getUint32(0);

    if (resultCode == DIAMETER_SUCCESS) {
      final ipAvp = aaa?.getAVP(AVP_FRAMED_IP_ADDRESS);
      if (ipAvp != null) {
        // Note: Real IP Address AVP includes 2 bytes for address family first
        final ip = ipAvp.data!.sublist(2);
        print('✅ Authentication successful! User assigned IP: ${ip.join('.')}');
      } else {
        print('✅ Authentication successful, but no IP address assigned.');
      }
    } else {
      print('❌ Authentication failed with Result-Code: $resultCode');
    }
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    client.disconnect();
  }
}
