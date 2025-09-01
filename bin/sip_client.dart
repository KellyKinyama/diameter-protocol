// bin/sip_client.dart

import 'dart:convert';
import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/sip/sip.dart';
import 'package:diameter_protocol/core/avp_dictionary2.dart';
import 'package:diameter_protocol/core/diameter_client2.dart';

Future<void> main() async {
  final serverHost = '127.0.0.1';
  final serverPort = 3868;
  final clientOriginHost = 'sip-proxy.dart.com';
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
      productName: 'DartSIP-Client',
    );
    final cea = await client.sendRequest(cer);
    if (cea?.getAVP(AVP_RESULT_CODE)?.data?.buffer.asByteData().getUint32(0) !=
        DIAMETER_SUCCESS) {
      throw Exception('CER failed.');
    }
    print('✅ CER/CEA exchange successful.\n');

    // 2. Request user authorization
    print('--- Step 2: Requesting User Authorization for a SIP AOR (UAR) ---');
    final sessionId =
        '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';

    final uar = UserAuthorizationRequest(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      sipAor: 'sip:user@dart.com',
    );

    final uaa = await client.sendRequest(uar);
    final resultCode = uaa
        ?.getAVP(AVP_RESULT_CODE)
        ?.data
        ?.buffer
        .asByteData()
        .getUint32(0);

    if (resultCode == DIAMETER_SUCCESS) {
      final serverUriAvp = uaa?.getAVP(AVP_SIP_SERVER_URI);
      if (serverUriAvp != null) {
        final uri = utf8.decode(serverUriAvp.data!);
        print('✅ SIP User Authorized. Assigned server: $uri');
      } else {
        print('✅ SIP User Authorized, but no server assigned.');
      }
    } else {
      print('❌ SIP User Authorization failed with Result-Code: $resultCode');
    }
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    client.disconnect();
  }
}
