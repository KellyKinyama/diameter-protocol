// bin/agent_example.dart

import 'package:diameter_protocol/agents/relay_agent.dart';
import 'package:diameter_protocol/agents/proxy_agent.dart';
import 'package:diameter_protocol/applications/session_management3.dart';

void main() async {
  // The final destination server
  final endServerHost = '127.0.0.1';
  final endServerPort = 3870;

  // --- Start the Proxy Agent ---
  // It will listen on port 3869 and forward to the end-server on 3870
  print("Starting Proxy Agent (Listens on 3869 -> Forwards to 3870)...");
  final proxyManager = DiameterSessionManager(
    originHost: 'proxy.dart.com',
    originRealm: 'dart.com',
  );
  final proxy = ProxyAgent(
    host: '127.0.0.1',
    port: 3869,
    nextHopHost: endServerHost,
    nextHopPort: endServerPort,
    sessionManager: proxyManager,
  );
  await proxy.start();

  // --- Start the Relay Agent ---
  // It will listen on port 3868 and forward to the proxy on 3869
  print("Starting Relay Agent (Listens on 3868 -> Forwards to 3869)...");
  final relayManager = DiameterSessionManager(
    originHost: 'relay.dart.com',
    originRealm: 'dart.com',
  );
  final relay = RelayAgent(
    host: '127.0.0.1',
    port: 3868,
    nextHopHost: '127.0.0.1',
    nextHopPort: 3869,
    sessionManager: relayManager,
  );
  await relay.start();
}
