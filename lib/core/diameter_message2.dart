// lib/core/diameter_message.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'avp_dictionary.dart';

// A simple map for pretty printing command codes in the toString() method.
const COMMANDS = {
  257: "Capabilities-Exchange",
  280: "Device-Watchdog",
  272: "Credit-Control",
  271: "Accounting",
  275: "Session-Termination",
  282: "Disconnect-Peer",
  258: "Re-Auth",
  274: "Abort-Session",
  316: "Update-Location",
  318: "Authentication-Information",
};

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
    final commandName = COMMANDS[commandCode] ?? commandCode.toString();
    return 'Diameter Message:\n'
        '  Version: $version, Length: $length, Flags: 0x${flags.toRadixString(16)}\n'
        '  Command Code: $commandName, Application ID: $applicationId\n'
        '  Hop-by-Hop ID: 0x${hopByHopId.toRadixString(16)}\n'
        '  End-to-End ID: 0x${endToEndId.toRadixString(16)}\n'
        '  AVPs:\n$avpStrings';
  }
}

class AVP {
  final int code;
  final int flags;
  final int vendorId;
  final Uint8List? data;
  final List<AVP>? avps;

  AVP({
    required this.code,
    this.flags = 0,
    this.data,
    this.avps,
    this.vendorId = 0,
  }) {
    if (data == null && avps == null) {
      throw ArgumentError('AVP must have either data or nested avps.');
    }
  }

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
    byteData.setUint16(0, rawAddress.length == 4 ? 1 : 2);
    data.setRange(2, data.length, rawAddress);
    return AVP(code: code, data: data);
  }

  factory AVP.fromGrouped(int code, List<AVP> avps) {
    return AVP(code: code, avps: avps, flags: 0x40);
  }

  factory AVP.decode(Uint8List rawAvp) {
    var byteData = ByteData.view(rawAvp.buffer);
    final code = byteData.getUint32(0);
    final flags = byteData.getUint8(4);
    final length = byteData.getUint32(4) & 0x00FFFFFF;

    int offset = 8;
    int vendorId = 0;
    if ((flags & 0x80) != 0) {
      vendorId = byteData.getUint32(8);
      offset = 12;
    }

    final data = rawAvp.sublist(offset, length);

    // --- THIS IS THE CRITICAL FIX ---
    // If the 'M' (Mandatory/Grouped) flag is set, recursively decode the data payload.
    if ((flags & 0x40) != 0) {
      List<AVP> innerAvps = [];
      int innerOffset = 0;
      while (innerOffset < data.length) {
        final innerAvp = AVP.decode(data.sublist(innerOffset));
        innerAvps.add(innerAvp);
        innerOffset += innerAvp.getPaddedLength();
      }
      return AVP(code: code, flags: flags, avps: innerAvps, vendorId: vendorId);
    }

    return AVP(code: code, flags: flags, data: data, vendorId: vendorId);
  }

  int getLength() {
    int headerLength = vendorId != 0 ? 12 : 8;
    if (data != null) {
      return headerLength + data!.length;
    }
    return headerLength +
        (avps?.fold(0, (sum, avp) => sum! + avp.getPaddedLength()) ?? 0);
  }

  int getPaddedLength() {
    final length = getLength();
    return (length + 3) & ~3;
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

    if (data != null) {
      buffer.setRange(offset, offset + data!.length, data!);
    } else if (avps != null) {
      int currentOffset = offset;
      for (final avp in avps!) {
        final encodedAvp = avp.encode();
        buffer.setRange(
          currentOffset,
          currentOffset + encodedAvp.length,
          encodedAvp,
        );
        currentOffset += encodedAvp.length;
      }
    }

    return buffer;
  }

  @override
  String toString() {
    String valueStr;
    try {
      if (avps != null) {
        final innerAvps = avps!.map((a) => '\n        $a').join('');
        valueStr = 'Grouped [$innerAvps\n    ]';
      } else if (data != null) {
        if (data!.length == 4) {
          valueStr = 'Unsigned32(${ByteData.view(data!.buffer).getUint32(0)})';
        } else {
          valueStr = 'UTF8String("${utf8.decode(data!)}")';
        }
      } else {
        valueStr = 'Empty';
      }
    } catch (_) {
      valueStr = 'OctetString(${data.toString()})';
    }
    final avpName = AVP_CODE_TO_NAME[code] ?? code.toString();
    return 'AVP(Code: $avpName, Flags: 0x${flags.toRadixString(16)}, Length: ${getLength()}, Value: $valueStr)';
  }
}
