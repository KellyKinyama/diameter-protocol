// bin/server_example.dart
import 'package:diameter_protocol/core/diameter_server2.dart';
import 'package:diameter_protocol/applications/session_manager.dart';

void main() async {
  final host = '127.0.0.1';
  final port = 3868;

  final sessionManager = DiameterSessionManager(
    originHost: 'server.dart.com',
    originRealm: 'dart.com',
  );

  final server = DiameterServer(host, port, sessionManager);
  await server.start();
}