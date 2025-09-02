// test/eap_test.dart

import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:diameter_protocol/applications/eap/eap.dart';
import 'package:diameter_protocol/core/diameter_message4.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';

void main() {
  group('DiameterEAPRequest', () {
    test('should generate a valid DER message', () {
      final eapPayload = Uint8List.fromList([
        0x01,
        0x01,
        0x00,
        0x05,
        0x01,
        0x01,
      ]);

      final derGenerator = DiameterEAPRequest(
        sessionId: 'eap-session;123',
        authRequestType: 1, // AUTHENTICATE_ONLY
        eapPayload: eapPayload,
      );

      final message = DiameterMessage(
        commandCode: 268,
        applicationId: 5,
        flags: DiameterMessage.FLAG_REQUEST,
        hopByHopId: 1,
        endToEndId: 1,
        generator: derGenerator,
      );

      expect(message.commandCode, 268);
      expect(message.getAVP(AVP_SESSION_ID)?.value, 'eap-session;123');

      final payloadAvp = message.getAVP(462); // EAP-Payload
      expect(payloadAvp, isNotNull);
      expect(payloadAvp!.value, equals(eapPayload));

      // Test end-to-end encoding and decoding
      final encoded = message.encode();
      final decoded = DiameterMessage.decode(encoded);

      expect(decoded.commandCode, message.commandCode);
      expect(decoded.getAVP(462)?.value, equals(eapPayload));
    });
  });
}
