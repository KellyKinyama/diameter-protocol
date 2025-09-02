// bin/server_example.dart

import 'package:diameter_protocol/core/diameter_server3.dart';
import 'package:diameter_protocol/applications/session_manager2.dart';
import 'package:diameter_protocol/applications/s6a/hss_service.dart';

void main() async {
  final host = '127.0.0.1';
  final port = 3868;

  // 1. Create an instance of our HSS application logic.
  final hssService = HssService();

  // 2. Inject the HSS service into the session manager.
  final sessionManager = DiameterSessionManager(
    originHost: 'hss.dart.com', // Server is now an HSS
    originRealm: 'dart.com',
    hssService: hssService,
  );

  final server = DiameterServer(host, port, sessionManager);
  await server.start();
}