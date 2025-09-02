// test/avp_test.dart

import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:diameter_protocol/core/diameter_avp.dart';

void main() {
  group('AVP Data Type Tests', () {
    test('AVPUnsigned32 should encode and decode correctly', () {
      final avp = AVPUnsigned32(268, 2001); // Result-Code
      final encoded = avp.encode();
      final decoded = AVP.decode(encoded);
      expect(decoded.code, 268);
      expect(decoded.value, 2001);
      expect(decoded, isA<AVPUnsigned32>());
    });

    test('AVPUTF8String should encode and decode correctly', () {
      final value = "hello_diameter";
      final avp = AVPUTF8String(264, value); // Origin-Host
      final encoded = avp.encode();
      final decoded = AVP.decode(encoded);
      expect(decoded.code, 264);
      expect(decoded.value, value);
      expect(decoded, isA<AVPUTF8String>());
    });

    test('AVPAddress should encode and decode IPv4 correctly', () {
      final value = "192.168.1.1";
      final avp = AVPAddress(8, value); // Framed-IP-Address
      final encoded = avp.encode();
      final decoded = AVP.decode(encoded);
      expect(decoded.code, 8);
      expect(decoded.value, value);
      expect(decoded, isA<AVPAddress>());
    });

    test('AVPGrouped should encode and decode correctly', () {
      final innerAvp1 = AVPUnsigned32(416, 1); // CC-Request-Type
      final innerAvp2 = AVPUnsigned32(415, 10); // CC-Request-Number
      final avp = AVPGrouped(456, [innerAvp1, innerAvp2]);

      final encoded = avp.encode();
      final decoded = AVP.decode(encoded);

      expect(decoded, isA<AVPGrouped>());
      expect((decoded as AVPGrouped).value, isA<List<AVP>>());
      final decodedInner = decoded.value as List<AVP>;
      expect(decodedInner.length, 2);
      expect(decodedInner[0].code, 416);
      expect(decodedInner[0].value, 1);
      expect(decodedInner[1].code, 415);
      expect(decodedInner[1].value, 10);
    });

    test('Vendor-specific AVP should encode and decode correctly', () {
      final avp = AVPUnsigned32(1032, 1004, vendorId: 10415); // RAT-Type
      final encoded = avp.encode();

      // Check header manually
      final byteData = ByteData.view(encoded.buffer);
      expect(byteData.getUint8(4) & 0x80, isNot(0)); // 'V' bit should be set
      expect(byteData.getUint32(8), 10415); // Vendor-Id field

      final decoded = AVP.decode(encoded);
      expect(decoded.code, 1032);
      expect(decoded.vendorId, 10415);
      expect(decoded.value, 1004);
    });
  });
}
