// bin/client_example.dart

import 'dart:typed_data';
import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/base/disconnect_peer.dart';
import 'package:diameter_protocol/applications/session_management.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control4.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/core/diameter_client2.dart';
import 'package:diameter_protocol/core/diameter_message2.dart';

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
      destinationRealm: 'dart.com',
      serviceContextId: 'example-service@dart.com',
    );
    final ccaInitial = await client.sendRequest(ccrInitial);
    print('✅ Received CCA-Initial, credit granted.');

    // Simulate using some of the granted data
    await Future.delayed(Duration(seconds: 1));

    // 3. Send an update, expecting to be told we're out of credit
    print(
      '\n--- Step 3: Reporting usage and requesting more credit (CCR-Update) ---',
    );
    final ccrUpdate = CreditControlRequest.update(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      requestNumber: 1,
      usedOctets: 4000, // Report usage
    );
    final ccaUpdate = await client.sendRequest(ccrUpdate);

    // Check if the server sent the Final-Unit-Indication
    final msccList =
        ccaUpdate?.avps
            .where((avp) => avp.code == AVP_MULTIPLE_SERVICES_CREDIT_CONTROL)
            .toList() ??
        [];
    bool isFinal = false;
    for (var mscc in msccList) {
      if (mscc.avps?.any((avp) => avp.code == AVP_FINAL_UNIT_INDICATION) ??
          false) {
        isFinal = true;
        break;
      }
    }

    if (isFinal) {
      print(
        '🔴 Received Final-Unit-Indication. The server has signaled the user is out of credit.',
      );
    } else {
      print('✅ Received more credit.');
    }

    // 4. Terminate the credit control session (CCR-Termination)
    print(
      '\n--- Step 4: Terminating the credit-control session (CCR-Termination) ---',
    );
    final ccrTerminate = CreditControlRequest.update(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      requestNumber: 2,
      usedOctets: 1000, // Report final usage
    );
    // Overwrite the CC-Request-Type to be TERMINATION_REQUEST
    ccrTerminate.avps
        .firstWhere((avp) => avp.code == AVP_CC_REQUEST_TYPE)
        .data = AVP
        .fromEnumerated(AVP_CC_REQUEST_TYPE, 3)
        .data;
    await client.sendRequest(ccrTerminate);
    print(
      '✅ CCR-T/CCA-T exchange successful. Credit-Control session terminated.\n',
    );

    // 5. Terminate the base protocol session
    print('--- Step 5: Terminating the base protocol session (STR) ---');
    final str = SessionTerminationRequest(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'dart.com',
      authApplicationId: APP_ID_CREDIT_CONTROL,
    );
    await client.sendRequest(str);
    print('✅ STR/STA exchange successful. Session terminated.\n');

    // Keep the connection open to observe the watchdog
    print('Client is now idle. Watchdog will fire in 5 seconds...');
    await Future.delayed(Duration(seconds: 6));
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    // 6. Gracefully disconnect
    print('\n--- Step 6: Gracefully disconnecting from peer (DPR) ---');
    final dpr = DisconnectPeerRequest(
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
    );
    // Fire-and-forget for DPR
    client.sendRequest(dpr, waitForResponse: false);
    await Future.delayed(Duration(milliseconds: 100)); // Give it time to send
    client.disconnect();
    print("✅ Client disconnected.");
  }
}
