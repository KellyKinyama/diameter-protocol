// test/base_protocol_test.dart

import 'package:diameter_protocol/core/diameter_avp.dart';
import 'package:test/test.dart';
import 'package:diameter_protocol/applications/base/watchdog3.dart';
import 'package:diameter_protocol/applications/base/disconnect_peer2.dart';
import 'package:diameter_protocol/core/diameter_message4.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';

void main() {
  group('DeviceWatchdog', () {
    test('DWR should be correctly constructed and encoded/decoded', () {
      final dwrGenerator = DeviceWatchdogRequest();

      final message = DiameterMessage(
        commandCode: 280,
        applicationId: 0,
        flags: DiameterMessage.FLAG_REQUEST,
        hopByHopId: 1,
        endToEndId: 1,
        generator: dwrGenerator,
      );

      // Add standard AVPs that the client framework would add
      message.avps.add(AVP.fromValue(AVP_ORIGIN_HOST, 'client.test.com'));
      message.avps.add(AVP.fromValue(AVP_ORIGIN_REALM, 'test.com'));

      final encoded = message.encode();
      final decoded = DiameterMessage.decode(encoded);

      expect(decoded.commandCode, 280);
      expect(decoded.getAVP(AVP_ORIGIN_HOST)?.value, 'client.test.com');
    });

    test('DWA should be correctly constructed', () {
      final dwaGenerator = DeviceWatchdogAnswer();
      // In a real scenario, the session manager adds Result-Code, etc.
      // Here, we are just testing the generator itself.
      expect(dwaGenerator.toAVPs(), isEmpty);
    });
  });

  group('DisconnectPeer', () {
    test('DPR should be correctly constructed', () {
      final dprGenerator = DisconnectPeerRequest(
        disconnectCause: 2, // BUSY
      );

      final message = DiameterMessage(
        commandCode: 282,
        applicationId: 0,
        flags: DiameterMessage.FLAG_REQUEST,
        hopByHopId: 1,
        endToEndId: 1,
        generator: dprGenerator,
      );

      expect(message.getAVP(AVP_DISCONNECT_CAUSE)?.value, 2);
    });
  });
}
