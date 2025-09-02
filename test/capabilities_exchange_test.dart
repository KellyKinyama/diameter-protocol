// test/capabilities_exchange_test.dart

import 'package:test/test.dart';
import 'package:diameter_protocol/applications/base/capabilities_exchange2.dart';
import 'package:diameter_protocol/core/diameter_message4.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';

void main() {
  group('CapabilitiesExchangeRequest', () {
    test('should generate a valid CER message', () {
      final cerGenerator = CapabilitiesExchangeRequest(
        originHost: 'client.test.com',
        originRealm: 'test.com',
        hostIpAddress: '127.0.0.1',
        vendorId: 10415,
        productName: 'DartTestClient',
        authApplicationIds: [16777251], // S6a
        supportedVendorIds: [10415],
      );

      final message = DiameterMessage(
        commandCode: 257,
        applicationId: 0,
        flags: DiameterMessage.FLAG_REQUEST,
        hopByHopId: 1,
        endToEndId: 1,
        generator: cerGenerator,
      );

      // Verify header
      expect(message.commandCode, 257);
      expect(message.flags & DiameterMessage.FLAG_REQUEST, isNot(0));

      // Verify AVPs
      expect(message.getAVP(AVP_ORIGIN_HOST)?.value, 'client.test.com');
      expect(message.getAVP(AVP_ORIGIN_REALM)?.value, 'test.com');
      expect(message.getAVP(AVP_PRODUCT_NAME)?.value, 'DartTestClient');
      expect(message.getAVP(AVP_AUTH_APPLICATION_ID)?.value, 16777251);
      expect(message.getAVP(AVP_SUPPORTED_VENDOR_ID)?.value, 10415);

      // Test end-to-end encoding and decoding
      final encoded = message.encode();
      final decoded = DiameterMessage.decode(encoded);

      expect(decoded.commandCode, message.commandCode);
      expect(decoded.getAVP(AVP_ORIGIN_HOST)?.value, 'client.test.com');
    });
  });
}
