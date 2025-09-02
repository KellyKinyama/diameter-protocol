// bin/client_example.dart

import 'package:diameter_protocol/applications/base/capabilities_exchange2.dart';
import 'package:diameter_protocol/applications/base/disconnect_peer2.dart';
import 'package:diameter_protocol/applications/base/session_management.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control5.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/core/diameter_client3.dart';

Future<void> main() async {
  // --- Configuration ---
  final serverHost = '127.0.0.1';
  final serverPort = 3868;
  final clientOriginHost = 'client.dart.com';
  final clientOriginRealm = 'dart.com';
  final sessionId =
      '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';

  final client = DiameterClient(
    host: serverHost,
    port: serverPort,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
    watchdogInterval: Duration(seconds: 5),
  );

  try {
    await client.connect();

    // 1. Capabilities Exchange
    print('--- Step 1: Performing Capabilities Exchange ---');
    await client.sendRequest(
      commandCode: 257,
      applicationId: 0,
      generator: CapabilitiesExchangeRequest(
        originHost: clientOriginHost,
        originRealm: clientOriginRealm,
        hostIpAddress: '127.0.0.1',
        vendorId: 10415,
        productName: 'DartDiameterV1',
        authApplicationIds: [4], // Credit-Control
      ),
    );
    print('✅ CER/CEA exchange successful.\n');

    // 2. Start an Online Charging Session
    print('--- Step 2: Starting Gy Session (CCR-Initial) ---');
    await client.sendRequest(
      commandCode: 272,
      applicationId: 4,
      generator: CreditControlRequest(
        sessionId: sessionId,
        requestType: 1, // INITIAL
        requestNumber: 0,
      ),
    );
    print('✅ Received CCA-Initial, credit granted.');

    // 3. Send an update
    print('\n--- Step 3: Reporting usage (CCR-Update) ---');
    final ccaUpdate = await client.sendRequest(
      commandCode: 272,
      applicationId: 4,
      generator: CreditControlRequest(
        sessionId: sessionId,
        requestType: 2, // UPDATE
        requestNumber: 1,
        usedOctets: 4000,
      ),
    );

    final fuiAvp = ccaUpdate?.getAVP(AVP_FINAL_UNIT_INDICATION);
    if (fuiAvp != null) {
      print('🔴 Received Final-Unit-Indication. User is out of credit.');
    } else {
      print('✅ Received more credit.');
    }

    // 4. Terminate the credit control session
    print(
      '\n--- Step 4: Terminating the credit-control session (CCR-Termination) ---',
    );
    await client.sendRequest(
      commandCode: 272,
      applicationId: 4,
      generator: CreditControlRequest(
        sessionId: sessionId,
        requestType: 3, // TERMINATION
        requestNumber: 2,
        usedOctets: 1000,
      ),
    );
    print('✅ CCR-T/CCA-T exchange successful.\n');

    // 5. Terminate the base protocol session
    print('--- Step 5: Terminating the base protocol session (STR) ---');
    await client.sendRequest(
      commandCode: 275,
      applicationId: 4,
      generator: SessionTerminationRequest(
        sessionId: sessionId,
        authApplicationId: 4,
      ),
    );
    print('✅ STR/STA exchange successful.\n');

    print('Client is now idle. Watchdog will fire in 5 seconds...');
    await Future.delayed(Duration(seconds: 6));
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    // 6. Gracefully disconnect
    print('\n--- Step 6: Gracefully disconnecting from peer (DPR) ---');
    client.sendRequest(
      commandCode: 282,
      applicationId: 0,
      generator: DisconnectPeerRequest(),
      waitForResponse: false,
    );
    await Future.delayed(Duration(milliseconds: 100));
    client.disconnect();
  }
}
