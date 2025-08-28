// bin/client_example.dart

import 'dart:typed_data';

import 'package:diameter_protocol/core/diameter_client3.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/base/disconnect_peer.dart';
import 'package:diameter_protocol/applications/session_management3.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control3.dart';

// Replace <your_project_name> with the name of your project in pubspec.yaml

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
//     watchdogInterval: Duration(seconds: 30), // Standard watchdog interval
//   );

//   try {
//     // --- 1. Connect to the server ---
//     await client.connect();

//     // --- 2. Perform Capabilities Exchange ---
//     print('--- Step 1: Performing Capabilities Exchange ---');
//     final cer = CapabilitiesExchangeRequest(
//       originHost: clientOriginHost,
//       originRealm: clientOriginRealm,
//       hostIpAddress: '127.0.0.1',
//       vendorId: 10415,
//       productName: 'DartDiameterV1',
//     );
//     final cea = await client.sendRequest(cer);

//     // Check the Result-Code AVP to ensure the exchange was successful
//     final resultCode = cea?.getAVP(AVP_RESULT_CODE);
//     if (resultCode == null ||
//         ByteData.view(resultCode.data.buffer).getUint32(0) != 2001) {
//       throw Exception('CER failed. Server returned non-success result code.');
//     }
//     print('✅ CER/CEA exchange successful.\n');

//     // --- 3. Start a new Credit-Control session ---
//     print('--- Step 2: Starting a new user session (CCR-Initial) ---');
//     final sessionId =
//         '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';
//     final ccrInitial = CreditControlRequest.initial(
//       sessionId: sessionId,
//       originHost: clientOriginHost,
//       originRealm: clientOriginRealm,
//       destinationRealm: 'server.dart.com',
//       userName: 'user@dart.com',
//     );
//     await client.sendRequest(ccrInitial);
//     print('✅ CCR-I/CCA-I exchange successful. Session is active.\n');

//     // Simulate user activity
//     await Future.delayed(Duration(seconds: 2));

//     // --- 4. Terminate the user session ---
//     print('--- Step 3: Terminating the user session (STR) ---');
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
//     // --- 5. Gracefully disconnect from the peer ---
//     print('--- Step 4: Gracefully disconnecting from peer (DPR) ---');
//     final dpr = DisconnectPeerRequest(
//       originHost: clientOriginHost,
//       originRealm: clientOriginRealm,
//       disconnectCause: 0, // 0 = REBOOTING
//     );
//     // For DPR, we send the request but don't wait for a response,
//     // as the server may close the connection immediately.
//     await client.sendRequest(dpr, waitForResponse: false);
//     client.disconnect();
//   }
// }

Future<void> main() async {
  // --- Configuration ---
  final serverHost = '127.0.0.1';
  final serverPort = 3868;
  final clientOriginHost = 'pcef.dart.com'; // Simulating a PCEF in a PGW
  final clientOriginRealm = 'dart.com';

  final client = DiameterClient(
    host: serverHost,
    port: serverPort,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
  );

  // try {
  await client.connect();

  // 1. Capabilities Exchange (unchanged)
  print('--- Step 1: Performing Capabilities Exchange ---');
  // ... (CER/CEA logic is the same)
  print('✅ CER/CEA exchange successful.\n');

  // 2. Start an Online Charging Session (Gy)
  print('--- Step 2: Starting Gy Session (CCR-Initial) ---');
  final sessionId =
      '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';

  // The PCEF requests an initial credit reservation
  final ccrInitial = CreditControlRequest.initial(
    sessionId: sessionId,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
    destinationRealm: 'ocs.dart.com',
  );
  final ccaInitial = await client.sendRequest(ccrInitial);
  print('✅ Received CCA-Initial, credit granted.');
  print('<< Received CCA (Initial):\n$ccaInitial');

  // 3. Send an interim update
  print(
    '\n--- Step 3: Reporting usage and requesting more credit (CCR-Update) ---',
  );
  await Future.delayed(Duration(seconds: 1)); // Simulate data usage
  final ccrUpdate = CreditControlRequest.update(
    sessionId: sessionId,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
    destinationRealm: 'ocs.dart.com',
    requestNumber: 1, // Next request number
    usedOctets: 450000, // Report usage
  );
  final ccaUpdate = await client.sendRequest(ccrUpdate);
  print('✅ Received CCA-Update, more credit granted.');
  print('<< Received CCA (Update):\n$ccaUpdate');

  // 4. Terminate the session
  print('\n--- Step 4: Terminating Gy Session (CCR-Terminate) ---');
  await Future.delayed(Duration(seconds: 1)); // Simulate final data usage
  final ccrTerminate = CreditControlRequest.terminate(
    sessionId: sessionId,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
    destinationRealm: 'ocs.dart.com',
    requestNumber: 2, // Final request number
    finalUsedOctets: 120000, // Report final usage
  );
  await client.sendRequest(ccrTerminate);
  print('✅ Received CCA-Terminate. Session closed.');
  // } catch (e) {
  //   print('❌ An error occurred: $e');
  // } finally {
  //   client.disconnect();
  // }
}
