// test/message_test.dart

import 'package:test/test.dart';
import 'package:diameter_protocol/core/diameter_message2.dart';
import 'package:diameter_protocol/core/diameter_avp.dart';
import 'dart:typed_data';

void main() {
  group('DiameterMessage Core Tests', () {
    // A real-world captured CER message, encoded as hex
    final cerHex =
        "010000b48000010100000000b237ee976801428f00000108400000216472612e73776c" +
        "61622e726f616d2e7365727665722e6e6574000000000001284000001d73776c61622e" +
        "726f616d2e7365727665722e6e6574000000000001014000000e0001ac142707000000" +
        "00010a4000000c0001869f0000010d0000001067795f72656c6179000001164000000c" +
        "64ae267e000001094000000c00000004000001054000000c0001869f";

    final cerBytes = Uint8List.fromList(
      List<int>.generate(
        cerHex.length ~/ 2,
        (i) => int.parse(cerHex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );

    test('should decode a complex raw message without errors', () {
      final message = DiameterMessage.decode(cerBytes);

      // Header checks
      expect(message.version, 1);
      expect(message.length, 180);
      expect(message.commandCode, 257);
      expect(message.applicationId, 0);
      expect(message.flags & DiameterMessage.FLAG_REQUEST, isNot(0));
      expect(message.hopByHopId, 0xb237ee97);
      expect(message.endToEndId, 0x6801428f);

      // AVP checks
      expect(message.avps.length, 9);
      expect(
        message.getAVP(264)?.data,
        'dra.swlab.roam.server.net',
      ); // Origin-Host
      expect(
        message.getAVP(296)?.data,
        'swlab.roam.server.net',
      ); // Origin-Realm
      expect(message.getAVP(266)?.data, 99999); // Vendor-Id
      expect(message.getAVP(269)?.data, 'gy_relay'); // Product-Name
    });

    test('re-encoding a decoded message should produce identical bytes', () {
      final message = DiameterMessage.decode(cerBytes);
      final reEncodedBytes = message.encode();
      expect(reEncodedBytes, equals(cerBytes));
    });
  });
}
