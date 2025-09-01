// bin/gy_client.dart

import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control4.dart';
import 'package:diameter_protocol/core/avp_dictionary2.dart';
import 'package:diameter_protocol/core/diameter_client2.dart';
import 'package:diameter_protocol/core/diameter_message3.dart';
import 'dart:typed_data';

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

    // 1. Capabilities Exchange (Advertise support for Gy)
    print('--- Step 1: Performing Capabilities Exchange ---');
    final cer = CapabilitiesExchangeRequest(
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      hostIpAddress: '127.0.0.1',
      vendorId: VENDOR_ID_3GPP,
      productName: 'DartPCEF-Client',
      supportedVendorIds: [VENDOR_ID_3GPP],
      // Advertise support for both standard CC and 3GPP Gy
      authApplicationIds: [APP_ID_CREDIT_CONTROL, APP_ID_3GPP_GY],
    );
    final cea = await client.sendRequest(cer);
    if (cea?.getAVP(AVP_RESULT_CODE)?.data?.buffer.asByteData().getUint32(0) !=
        DIAMETER_SUCCESS) {
      throw Exception(
        'CER failed. Does server support Gy (AppId ${APP_ID_3GPP_GY}})?',
      );
    }
    print('✅ CER/CEA exchange successful.\n');

    // 2. Start Gy Session for a user
    print('--- Step 2: Starting Gy Online Charging Session (CCR-Initial) ---');
    final sessionId =
        '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';
    final imsi = "123456789012345";

    final ccrInitial =
        CreditControlRequest.initial(
            sessionId: sessionId,
            originHost: clientOriginHost,
            originRealm: clientOriginRealm,
            destinationRealm: 'dart.com',
            serviceContextId: 'gy_service@3gpp.org',
          )
          // Add Gy specific AVPs
          ..avps.add(
            AVP.fromGrouped(AVP_SUBSCRIPTION_ID, [
              AVP.fromEnumerated(AVP_SUBSCRIPTION_ID_TYPE, 1), // END_USER_IMSI
              AVP.fromString(AVP_SUBSCRIPTION_ID_DATA, imsi),
            ]),
          );

    final ccaInitial = await client.sendRequest(ccrInitial);
    if (ccaInitial
            ?.getAVP(AVP_RESULT_CODE)
            ?.data
            ?.buffer
            .asByteData()
            .getUint32(0) !=
        DIAMETER_SUCCESS) {
      throw Exception('CCR-Initial failed.');
    }
    print('✅ Gy Session started. Credit granted.');
    print(ccaInitial);

    // 3. Report usage and request more credit
    print('\n--- Step 3: Reporting Usage (CCR-Update) ---');
    final ccrUpdate = CreditControlRequest.update(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      requestNumber: 1,
      usedOctets: 4000,
    );
    final ccaUpdate = await client.sendRequest(ccrUpdate);
    final resultCode = ccaUpdate
        ?.getAVP(AVP_RESULT_CODE)
        ?.data
        ?.buffer
        .asByteData()
        .getUint32(0);

    if (resultCode != DIAMETER_SUCCESS) {
      print('❌ CCR-Update failed with code: $resultCode');
    } else {
      final fui = ccaUpdate?.getAVP(AVP_FINAL_UNIT_INDICATION);
      if (fui != null) {
        print('🔴 Received Final-Unit-Indication. User is out of credit.');
      } else {
        print('✅ More credit granted.');
      }
    }

    // 4. Terminate the Gy session
    print('\n--- Step 4: Terminating Gy Session (CCR-Termination) ---');
    final ccrTerminate = CreditControlRequest.update(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      requestNumber: 2,
      usedOctets: 1000, // Final used amount
    );
    // Overwrite the request type to TERMINATION
    ccrTerminate.avps
        .firstWhere((avp) => avp.code == AVP_CC_REQUEST_TYPE)
        .data = AVP
        .fromEnumerated(AVP_CC_REQUEST_TYPE, 3)
        .data;

    await client.sendRequest(ccrTerminate);
    print('✅ Gy Session terminated successfully.');
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    client.disconnect();
  }
}
