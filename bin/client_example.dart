// bin/client_example.dart

import 'dart:typed_data';

import 'package:diameter_protocol/applications/base/accounting.dart';
import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/base/disconnect_peer.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control3.dart';
// import 'package:diameter_protocol/applications/credit_control/credit_control2.dart';
import 'package:diameter_protocol/applications/session_management.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/core/diameter_client2.dart';
import 'package:diameter_protocol/core/diameter_message2.dart';

// Future<void> main() async {
//   final serverHost = '127.0.0.1';
//   final serverPort = 3868;
//   final clientOriginHost = 'client.dart.com';
//   final clientOriginRealm = 'dart.com';

//   final client = DiameterClient(
//     host: serverHost,
//     port: serverPort,
//     originHost: clientOriginHost,
//     originRealm: clientOriginRealm,
//     watchdogInterval: Duration(seconds: 30),
//   );

//   try {
//     await client.connect();

//     // 1. Capabilities Exchange
//     print('--- Step 1: Performing Capabilities Exchange ---');
//     final cer = CapabilitiesExchangeRequest(
//       originHost: clientOriginHost,
//       originRealm: clientOriginRealm,
//       hostIpAddress: '127.0.0.1',
//       vendorId: 10415,
//       productName: 'DartDiameterV1',
//     );
//     final cea = await client.sendRequest(cer);
//     final resultCode = cea?.getAVP(AVP_RESULT_CODE);
//     if (resultCode == null ||
//         ByteData.view(resultCode.data!.buffer).getUint32(0) != 2001) {
//       throw Exception('CER failed.');
//     }
//     print('✅ CER/CEA exchange successful.\n');

//     // 2. Start a Credit-Control session
//     print('--- Step 2: Starting a new user session (CCR-Initial) ---');
//     final sessionId =
//         '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';

//     final ccrInitial = CreditControlRequest.initial(
//       sessionId: sessionId,
//       originHost: clientOriginHost,
//       originRealm: clientOriginRealm,
//       destinationRealm: 'ocs.dart.com',
//     );
//     await client.sendRequest(ccrInitial);
//     print('✅ CCR-I/CCA-I exchange successful. Session is active.\n');

//     // 3. Send Accounting-Request START
//     print('--- Step 3: Sending Accounting Start (ACR-Start) ---');
//     final acrStart = AccountingRequest.start(
//       sessionId: sessionId,
//       originHost: clientOriginHost,
//       originRealm: clientOriginRealm,
//       destinationRealm: 'server.dart.com',
//     );
//     await client.sendRequest(acrStart);
//     print('✅ ACR-Start/ACA-Start exchange successful.\n');

//     await Future.delayed(Duration(seconds: 2));

//     // 4. Send Accounting-Request STOP
//     print('--- Step 4: Sending Accounting Stop (ACR-Stop) ---');
//     final acrStop = AccountingRequest.stop(
//       sessionId: sessionId,
//       originHost: clientOriginHost,
//       originRealm: clientOriginRealm,
//       destinationRealm: 'server.dart.com',
//       recordNumber: 1,
//     );
//     await client.sendRequest(acrStop);
//     print('✅ ACR-Stop/ACA-Stop exchange successful.\n');

//     // 5. Terminate the user session
//     print('--- Step 5: Terminating the user session (STR) ---');
//     final str = SessionTerminationRequest(
//       sessionId: sessionId,
//       originHost: clientOriginHost,
//       originRealm: clientOriginRealm,
//       destinationRealm: 'server.dart.com',
//       authApplicationId: APP_ID_CREDIT_CONTROL,
//     );
//     await client.sendRequest(str);
//     print('✅ STR/STA exchange successful. Session terminated.\n');
//   } catch (e) {
//     print('❌ An error occurred: $e');
//   } finally {
//     // 6. Gracefully disconnect from the peer
//     print('--- Step 6: Gracefully disconnecting from peer (DPR) ---');
//     final dpr = DisconnectPeerRequest(
//       originHost: clientOriginHost,
//       originRealm: clientOriginRealm,
//     );
//     await client.sendRequest(dpr, waitForResponse: false);
//     client.disconnect();
//   }
// }

// bin/client_example.dart

// ... (imports)

// Future<void> main() async {
//   // --- Configuration ---
//   final serverHost = '127.0.0.1';
//   final serverPort = 3868;
//   final clientOriginHost = 'client.dart.com';
//   final clientOriginRealm = 'dart.com';

//   final client = DiameterClient(
//     host: serverHost,
//     port: serverPort,
//     originHost: clientOriginHost,
//     originRealm: clientOriginRealm,
//     watchdogInterval: Duration(seconds: 30),
//   );

//   try {
//     await client.connect();

//     // 1. Capabilities Exchange
//     print('--- Step 1: Performing Capabilities Exchange ---');
//     final cer = CapabilitiesExchangeRequest(
//       originHost: clientOriginHost,
//       originRealm: clientOriginRealm,
//       hostIpAddress: '127.0.0.1',
//       vendorId: 10415,
//       productName: 'DartDiameterV1',
//     );
//     final cea = await client.sendRequest(cer);
//     final resultCode = cea?.getAVP(AVP_RESULT_CODE);
//     if (resultCode == null ||
//         ByteData.view(resultCode.data!.buffer).getUint32(0) !=
//             DIAMETER_SUCCESS) {
//       throw Exception('CER failed.');
//     }
//     print('✅ CER/CEA exchange successful.\n');

//     // 2. Start a compliant Credit-Control session
//     print('--- Step 2: Starting Gy Session (CCR-Initial) ---');
//     final sessionId =
//         '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';

//     final ccrInitial = CreditControlRequest.initial(
//       sessionId: sessionId,
//       originHost: clientOriginHost,
//       originRealm: clientOriginRealm,
//       destinationRealm: 'ocs.dart.com',
//       serviceContextId: 'example-service@dart.com',
//     );
//     final ccaInitial = await client.sendRequest(ccrInitial);

//     // --- FIX: Correctly parse the nested Grouped AVPs in the CCA ---
//     final msccAvp = ccaInitial?.getAVP(AVP_MULTIPLE_SERVICES_CREDIT_CONTROL);
//     if (msccAvp != null && msccAvp.avps != null) {
//       final gsuAvp = msccAvp.avps!.firstWhere(
//         (avp) => avp.code == AVP_GRANTED_SERVICE_UNIT,
//         orElse: () => AVP(code: 0, data: Uint8List(0)),
//       );
//       if (gsuAvp.avps != null) {
//         final totalOctetsAvp = gsuAvp.avps!.firstWhere(
//           (avp) => avp.code == AVP_CC_TOTAL_OCTETS,
//           orElse: () => AVP(code: 0, data: Uint8List(0)),
//         );
//         if (totalOctetsAvp.data != null) {
//           final grantedAmount = ByteData.view(
//             totalOctetsAvp.data!.buffer,
//           ).getUint32(0);
//           print('✅ Received CCA with $grantedAmount granted octets.');
//         } else {
//           throw Exception('CCA did not contain CC-Total-Octets AVP.');
//         }
//       } else {
//         throw Exception('CCA did not contain GSU AVP inside MSCC.');
//       }
//     } else {
//       throw Exception('CCA did not contain MSCC AVP.');
//     }
//   } catch (e) {
//     print('❌ An error occurred: $e');
//   } finally {
//     client.disconnect();
//   }
// }

Future<void> main() async {
  // --- Configuration ---
  final serverHost = '127.0.0.1';
  final serverPort = 3868;
  final clientOriginHost = 'client.dart.com';
  final clientOriginRealm = 'dart.com';

  final client = DiameterClient(
    host: serverHost,
    port: serverPort,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
    watchdogInterval: Duration(seconds: 5), // Short interval for testing
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
      productName: 'DartDiameterV1',
    );
    final cea = await client.sendRequest(cer);
    final resultCode = cea?.getAVP(AVP_RESULT_CODE);
    if (resultCode == null ||
        ByteData.view(resultCode.data!.buffer).getUint32(0) !=
            DIAMETER_SUCCESS) {
      throw Exception('CER failed.');
    }
    print('✅ CER/CEA exchange successful.\n');

    // 2. Start an Online Charging Session
    print('--- Step 2: Starting Gy Session (CCR-Initial) ---');
    final sessionId =
        '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';

    final ccrInitial = CreditControlRequest.initial(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'ocs.dart.com',
      serviceContextId: 'example-service@dart.com',
    );
    final ccaInitial = await client.sendRequest(ccrInitial);
    print('✅ Received CCA-Initial, credit granted.');

    // Simulate using the granted data
    await Future.delayed(Duration(seconds: 1));

    // 3. Send an update, expecting to be told we're out of credit
    print(
      '\n--- Step 3: Reporting usage and requesting more credit (CCR-Update) ---',
    );
    final ccrUpdate = CreditControlRequest.update(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'ocs.dart.com',
      requestNumber: 1,
      usedOctets: 1024,
    );
    final ccaUpdate = await client.sendRequest(ccrUpdate);

    // Check if the server sent the Final-Unit-Indication
    final fuiAvp = ccaUpdate?.getAVP(AVP_FINAL_UNIT_INDICATION);
    if (fuiAvp != null) {
      print(
        '🔴 Received Final-Unit-Indication. The server has signaled the user is out of credit.',
      );
    } else {
      print('✅ Received more credit.');
    }

    // 4. Terminate the user session
    print('\n--- Step 4: Terminating the user session (STR) ---');
    final str = SessionTerminationRequest(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'ocs.dart.com',
      authApplicationId: APP_ID_CREDIT_CONTROL,
    );
    await client.sendRequest(str);
    print('✅ STR/STA exchange successful. Session terminated.\n');

    // FIX: Add a delay here to keep the connection open and see the watchdog fire
    print('Client is now idle. Watchdog will fire in 5 seconds...');
    await Future.delayed(Duration(seconds: 6));
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    // 5. Gracefully disconnect
    print('\n--- Step 5: Gracefully disconnecting from peer (DPR) ---');
    final dpr = DisconnectPeerRequest(
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
    );
    await client.sendRequest(dpr, waitForResponse: false);
    client.disconnect();
  }
}
