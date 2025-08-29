// lib/core/diameter_message.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:diameter_protocol/core/avp_dictionary.dart';

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

  DiameterMessage({
    required this.version,
    required this.length,
    required this.flags,
    required this.commandCode,
    required this.applicationId,
    required this.hopByHopId,
    required this.endToEndId,
    required this.avps,
  });

  factory DiameterMessage.fromFields({
    required int commandCode,
    required int applicationId,
    required int flags,
    required int hopByHopId,
    required int endToEndId,
    required List<AVP> avpList,
    int version = 1,
  }) {
    int totalLength = 20; // Header size
    for (final avp in avpList) {
      totalLength += avp.getPaddedLength();
    }

    return DiameterMessage(
      version: version,
      length: totalLength,
      flags: flags,
      commandCode: commandCode,
      applicationId: applicationId,
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
      avps: avpList,
    );
  }

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

    return DiameterMessage(
      version: version,
      length: length,
      flags: flags,
      commandCode: commandCode,
      applicationId: applicationId,
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
      avps: avps,
    );
  }

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

  AVP? getAVP(int code) {
    try {
      return avps.firstWhere((avp) => avp.code == code);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    final avpStrings = avps.map((avp) => '    $avp').join('\n');
    return 'Diameter Message:\n'
        '  Version: $version, Length: $length, Flags: 0x${flags.toRadixString(16)}\n'
        '  Command Code: ${COMMAND_CODE_TO_NAME[commandCode]}, Application ID: $applicationId\n'
        '  Hop-by-Hop ID: 0x${hopByHopId.toRadixString(16)}\n'
        '  End-to-End ID: 0x${endToEndId.toRadixString(16)}\n'
        '  AVPs:\n$avpStrings';
  }
}

class AVP {
  final int code;
  final int flags;
  final Uint8List data;
  final int vendorId;

  AVP({
    required this.code,
    this.flags = 0,
    required this.data,
    this.vendorId = 0,
  });

  // Helper factories for creating AVPs with correct types
  factory AVP.fromString(int code, String value) {
    return AVP(code: code, data: utf8.encode(value) as Uint8List);
  }

  factory AVP.fromUnsigned32(int code, int value) {
    var byteData = ByteData(4)..setUint32(0, value);
    return AVP(code: code, data: byteData.buffer.asUint8List());
  }

  factory AVP.fromEnumerated(int code, int value) {
    return AVP.fromUnsigned32(code, value);
  }

  factory AVP.fromAddress(int code, String ipAddress) {
    var rawAddress = InternetAddress(ipAddress).rawAddress;
    var data = Uint8List(2 + rawAddress.length);
    var byteData = ByteData.view(data.buffer);
    // Address Family (1 for IPv4, 2 for IPv6)
    byteData.setUint16(0, rawAddress.length == 4 ? 1 : 2);
    data.setRange(2, data.length, rawAddress);
    return AVP(code: code, data: data);
  }

  factory AVP.decode(Uint8List rawAvp) {
    var byteData = ByteData.view(rawAvp.buffer);
    final code = byteData.getUint32(0);
    final flags = byteData.getUint8(4);
    final length = byteData.getUint32(4) & 0x00FFFFFF;

    int offset = 8;
    int vendorId = 0;
    if ((flags & 0x80) != 0) {
      // Vendor-Specific bit is set
      vendorId = byteData.getUint32(8);
      offset = 12;
    }

    final data = rawAvp.sublist(offset, length);
    return AVP(code: code, flags: flags, data: data, vendorId: vendorId);
  }

  int getLength() {
    int length = 8 + data.length; // 8 bytes for header
    if (vendorId != 0) {
      length += 4;
    }
    return length;
  }

  int getPaddedLength() {
    final length = getLength();
    return (length + 3) & ~3; // Pad to the next 4-byte boundary
  }

  Uint8List encode() {
    final length = getLength();
    final paddedLength = getPaddedLength();
    final buffer = Uint8List(paddedLength);
    final byteData = ByteData.view(buffer.buffer);

    byteData.setUint32(0, code);
    byteData.setUint8(4, flags | (vendorId != 0 ? 0x80 : 0));
    byteData.setUint32(4, (byteData.getUint32(4) & 0xFF000000) | length);

    int offset = 8;
    if (vendorId != 0) {
      byteData.setUint32(8, vendorId);
      offset = 12;
    }

    buffer.setRange(offset, offset + data.length, data);

    return buffer;
  }

  @override
  String toString() {
    String valueStr;
    try {
      if (data.length == 4) {
        valueStr = 'Unsigned32(${ByteData.view(data.buffer).getUint32(0)})';
      } else {
        valueStr = 'UTF8String("${utf8.decode(data)}")';
      }
    } catch (_) {
      valueStr = 'OctetString(${data.toString()})';
    }
    return 'AVP(Code: ${COMMAND_CODE_TO_NAME[code]}, Flags: 0x${flags.toRadixString(16)}, Length: ${getLength()}, Value: $valueStr)';
  }
}
