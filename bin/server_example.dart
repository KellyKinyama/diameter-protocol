// bin/server_example.dart

import 'package:diameter_protocol/core/diameter_server.dart';
import 'package:diameter_protocol/applications/session_management3.dart';

void main() async {
  final host = '127.0.0.1';
  final port = 3868;

  // Create a session manager with the server's identity
  final sessionManager = DiameterSessionManager(
    originHost: 'server.dart.com',
    originRealm: 'dart.com',
  );

  // Create and start the server
  final server = DiameterServer(host, port, sessionManager);
  await server.start();
}
