// test/credit_control_test.dart

import 'package:test/test.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control5.dart';
import 'package:diameter_protocol/core/diameter_message4.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/core/diameter_avp.dart';

void main() {
  group('CreditControlRequest', () {
    test('should generate a valid CCR-Initial', () {
      final ccrGenerator = CreditControlRequest(
        sessionId: 'test-session;123',
        requestType: 1, // INITIAL
        requestNumber: 0,
      );

      final message = DiameterMessage(
        commandCode: 272,
        applicationId: 4,
        flags: DiameterMessage.FLAG_REQUEST,
        hopByHopId: 1,
        endToEndId: 1,
        generator: ccrGenerator,
      );

      expect(message.getAVP(AVP_SESSION_ID)?.value, 'test-session;123');
      expect(message.getAVP(AVP_CC_REQUEST_TYPE)?.value, 1);
      expect(message.getAVP(AVP_CC_REQUEST_NUMBER)?.value, 0);
    });

    test('should generate a valid CCR-Update with Used-Service-Unit', () {
      final ccrGenerator = CreditControlRequest(
        sessionId: 'test-session;123',
        requestType: 2, // UPDATE
        requestNumber: 1,
        usedOctets: 5120,
      );

      final message = DiameterMessage(
        commandCode: 272,
        applicationId: 4,
        flags: DiameterMessage.FLAG_REQUEST,
        hopByHopId: 2,
        endToEndId: 2,
        generator: ccrGenerator,
      );

      final usuAvp = message.getAVP(AVP_USED_SERVICE_UNIT);
      expect(usuAvp, isNotNull);
      expect(usuAvp, isA<AVPGrouped>());

      final innerAvps = usuAvp!.value as List<AVP>;
      final octetsAvp = innerAvps.firstWhere(
        (avp) => avp.code == AVP_CC_TOTAL_OCTETS,
      );
      expect(octetsAvp.value, 5120);
    });
  });
}
