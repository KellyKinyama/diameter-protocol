// lib/core/diameter_message2.dart

import 'dart:convert';
import 'dart:typed_data';
import 'diameter_avp.dart';
import 'avp_dictionary.dart';
import 'message_generator.dart';

class DiameterMessage {
  // --- Header Flags ---
  static const int FLAG_REQUEST = 0x80;
  static const int FLAG_PROXYABLE = 0x40;
  static const int FLAG_ERROR = 0x20;
  static const int FLAG_RETRANSMITTED = 0x10;

  final int version;
  final int length;
  final int flags;
  final int commandCode;
  final int applicationId;
  final int hopByHopId;
  final int endToEndId;
  final List<AVP> avps;

  // Primary constructor is now simpler
  DiameterMessage({
    required this.commandCode,
    required this.applicationId,
    required this.flags,
    required this.hopByHopId,
    required this.endToEndId,
    required MessageGenerator generator,
    this.version = 1,
  }) : avps = generator.toAVPs(),
       length =
           20 +
           generator.toAVPs().fold(
             0,
             (sum, avp) => sum + avp.getPaddedLength(),
           );

  /// Decodes raw bytes into a DiameterMessage.
  factory DiameterMessage.decode(Uint8List data) {
    if (data.length < 20) {
      throw FormatException('Invalid Diameter message length: ${data.length}');
    }

    var byteData = ByteData.view(data.buffer);
    final version = byteData.getUint8(0);
    final length = byteData.getUint32(0) & 0x00FFFFFF;
    final flags = byteData.getUint8(4);
    final commandCode = byteData.getUint32(4) & 0x00FFFFFF;
    final applicationId = byteData.getUint32(8);
    final hopByHopId = byteData.getUint32(12);
    final endToEndId = byteData.getUint32(16);

    List<AVP> avps = [];
    int offset = 20;
    while (offset < length) {
      final avp = AVP.decode(data.sublist(offset));
      avps.add(avp);
      offset += avp.getPaddedLength();
    }
    return DiameterMessage._internal(
      version,
      length,
      flags,
      commandCode,
      applicationId,
      hopByHopId,
      endToEndId,
      avps,
    );
  }

  // Private internal constructor for decoding
  DiameterMessage._internal(
    this.version,
    this.length,
    this.flags,
    this.commandCode,
    this.applicationId,
    this.hopByHopId,
    this.endToEndId,
    this.avps,
  );

  Uint8List encode() {
    final buffer = BytesBuilder();
    // Header
    var headerByteData = ByteData(20);
    headerByteData.setUint8(0, version);
    headerByteData.setUint32(
      0,
      (headerByteData.getUint32(0) & 0xFF000000) | length,
    );
    headerByteData.setUint8(4, flags);
    headerByteData.setUint32(
      4,
      (headerByteData.getUint32(4) & 0xFF000000) | commandCode,
    );
    headerByteData.setUint32(8, applicationId);
    headerByteData.setUint32(12, hopByHopId);
    headerByteData.setUint32(16, endToEndId);
    buffer.add(headerByteData.buffer.asUint8List());

    // AVPs
    for (final avp in avps) {
      buffer.add(avp.encode());
    }
    return buffer.toBytes();
  }

  static int generateId() {
    return DateTime.now().microsecondsSinceEpoch & 0xFFFFFFFF;
  }

  AVP? getAVP(int code, {int vendorId = 0}) {
    try {
      return avps.firstWhere(
        (avp) => avp.code == code && avp.vendorId == vendorId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    final avpStrings = avps.map((avp) => '    $avp').join('\n');
    final commandName =
        COMMAND_CODE_TO_NAME[commandCode] ?? commandCode.toString();
    return 'Diameter Message:\n'
        '  Version: $version, Length: $length, Flags: 0x${flags.toRadixString(16)}\n'
        '  Command Code: $commandName, Application ID: $applicationId\n'
        '  Hop-by-Hop ID: 0x${hopByHopId.toRadixString(16)}\n'
        '  End-to-End ID: 0x${endToEndId.toRadixString(16)}\n'
        '  AVPs:\n$avpStrings';
  }
}
