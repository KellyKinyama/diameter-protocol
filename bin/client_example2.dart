// bin/client_example.dart

import 'package:diameter_protocol/core/diameter_client2.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control.dart';

// Replace <your_project_name> with the name of your project in pubspec.yaml

Future<void> main() async {
  final serverHost = '127.0.0.1';
  final serverPort = 3868;

  // The client now needs its own identity to create watchdog messages
  final client = DiameterClient(
    host: serverHost,
    port: serverPort,
    originHost: 'client.dart.com',
    originRealm: 'dart.com',
    watchdogInterval: Duration(seconds: 5), // Shorter interval for testing
  );

  try {
    await client.connect();

    // 1. Perform Capabilities Exchange
    final cer = CapabilitiesExchangeRequest(
      originHost: 'client.dart.com',
      originRealm: 'dart.com',
      hostIpAddress: '127.0.0.1',
      vendorId: 10415,
      productName: 'DartDiameterV1',
    );
    final cea = await client.sendRequest(cer);
    print(
      '✅ Received CEA with Result-Code: ${cea.getAVP(AVP_RESULT_CODE)?.data[3]}',
    );

    // 2. Start a new Credit-Control session
    final sessionId =
        'client.dart.com;${DateTime.now().millisecondsSinceEpoch}';
    final ccrInitial = CreditControlRequest.initial(
      sessionId: sessionId,
      originHost: 'client.dart.com',
      originRealm: 'dart.com',
      destinationRealm: 'server.dart.com',
      userName: 'user@dart.com',
    );
    final ccaInitial = await client.sendRequest(ccrInitial);
    print(
      '✅ Received CCA with Result-Code: ${ccaInitial.getAVP(AVP_RESULT_CODE)?.data[3]}',
    );

    // Keep the client running to see the watchdog fire
    print('\nClient is now idle. Watchdog will fire in 5 seconds...');
    await Future.delayed(Duration(seconds: 10));
  } catch (e) {
    print('❌ An error occurred: $e');
  } finally {
    client.disconnect();
  }
}
