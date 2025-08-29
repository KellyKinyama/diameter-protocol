// bin/end_server.dart

import 'package:diameter_protocol/core/diameter_server.dart';
import 'package:diameter_protocol/applications/session_management.dart';

void main() async {
  print("Starting End Server...");
  final sessionManager = DiameterSessionManager(
    originHost: 'end-server.dart.com',
    originRealm: 'dart.com',
  );

  final server = DiameterServer('127.0.0.1', 3870, sessionManager);
  await server.start();
}
