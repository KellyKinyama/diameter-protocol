// bin/client_example.dart

import 'dart:typed_data';

import 'package:diameter_protocol/applications/base/accounting.dart';
import 'package:diameter_protocol/applications/base/capabilities_exchange2.dart';
import 'package:diameter_protocol/applications/base/disconnect_peer2.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control2.dart';
import 'package:diameter_protocol/applications/session_management4.dart';
import 'package:diameter_protocol/core/avp_dictionary3.dart';
import 'package:diameter_protocol/core/diameter_client4.dart';

Future<void> main() async {
  final serverHost = '127.0.0.1';
  final serverPort = 3868;
  final clientOriginHost = 'client.dart.com';
  final clientOriginRealm = 'dart.com';

  final client = DiameterClient(
    host: serverHost,
    port: serverPort,
    originHost: clientOriginHost,
    originRealm: clientOriginRealm,
    watchdogInterval: Duration(seconds: 30),
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
        ByteData.view(resultCode.data.buffer).getUint32(0) != 2001) {
      throw Exception('CER failed.');
    }
    print('✅ CER/CEA exchange successful.\n');

    // 2. Start a Credit-Control session
    print('--- Step 2: Starting a new user session (CCR-Initial) ---');
    final sessionId =
        '$clientOriginHost;${DateTime.now().millisecondsSinceEpoch}';
    final ccrInitial = CreditControlRequest.initial(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'server.dart.com',
      userName: 'user@dart.com',
    );
    await client.sendRequest(ccrInitial);
    print('✅ CCR-I/CCA-I exchange successful. Session is active.\n');

    // 3. Send Accounting-Request START
    print('--- Step 3: Sending Accounting Start (ACR-Start) ---');
    final acrStart = AccountingRequest.start(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'server.dart.com',
    );
    await client.sendRequest(acrStart);
    print('✅ ACR-Start/ACA-Start exchange successful.\n');

    await Future.delayed(Duration(seconds: 2));

    // 4. Send Accounting-Request STOP
    print('--- Step 4: Sending Accounting Stop (ACR-Stop) ---');
    final acrStop = AccountingRequest.stop(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'server.dart.com',
      recordNumber: 1,
    );
    await client.sendRequest(acrStop);
    print('✅ ACR-Stop/ACA-Stop exchange successful.\n');

    // 5. Terminate the user session
    print('--- Step 5: Terminating the user session (STR) ---');
    final str = SessionTerminationRequest(
      sessionId: sessionId,
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
      destinationRealm: 'server.dart.com',
      authApplicationId: APP_ID_CREDIT_CONTROL,
    );
    await client.sendRequest(str);
    print('✅ STR/STA exchange successful. Session terminated.\n');
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    // 6. Gracefully disconnect from the peer
    print('--- Step 6: Gracefully disconnecting from peer (DPR) ---');
    final dpr = DisconnectPeerRequest(
      originHost: clientOriginHost,
      originRealm: clientOriginRealm,
    );
    await client.sendRequest(dpr, waitForResponse: false);
    client.disconnect();
  }
}
