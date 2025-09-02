// lib/core/diameter_avp.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'avp_dictionary3.dart';
import 'diameter_exception.dart';

/// Abstract Base Class for all AVPs.
abstract class AVP {
  final int code;
  int flags;
  final int vendorId;
  dynamic value;

  AVP(this.code, this.value, {this.flags = 0, this.vendorId = 0});

  /// Factory to create the correct AVP subclass from a code and value.
  factory AVP.fromValue(int code, dynamic value, {int vendorId = 0}) {
    final definition = (vendorId == 0)
        ? AVP_DICTIONARY[code]
        : VENDOR_AVP_DICTIONARIES[vendorId]?[code];

    if (definition == null) {
      throw AVPEncodeException(
        "Unknown AVP code $code with vendorId $vendorId",
      );
    }

    final avp = _createInstance(
      definition.type,
      code,
      value,
      vendorId: vendorId,
    );
    if (definition.isMandatory) {
      avp.flags |= 0x40; // Set 'M' bit
    }
    return avp;
  }

  /// Factory to decode raw bytes into the correct AVP subclass.
  factory AVP.decode(Uint8List data) {
    var byteData = ByteData.view(data.buffer);
    final avpCode = byteData.getUint32(0);
    final flags = byteData.getUint8(4);
    final length = byteData.getUint32(4) & 0x00FFFFFF;

    int offset = 8;
    int vendorId = 0;
    if ((flags & 0x80) != 0) {
      vendorId = byteData.getUint32(8);
      offset = 12;
    }

    final definition = (vendorId == 0)
        ? AVP_DICTIONARY[avpCode]
        : VENDOR_AVP_DICTIONARIES[vendorId]?[avpCode];

    final avpType = definition?.type ?? AVPOctetString;

    final avp = _createInstance(
      avpType,
      avpCode,
      null,
      vendorId: vendorId,
      flags: flags,
    );
    avp._decodeData(data.sublist(offset, length));
    return avp;
  }

  static AVP _createInstance(
    Type type,
    int code,
    dynamic value, {
    int vendorId = 0,
    int flags = 0,
  }) {
    switch (type) {
      case AVPUnsigned32:
        return AVPUnsigned32(code, value, vendorId: vendorId, flags: flags);
      case AVPUnsigned64:
        return AVPUnsigned64(code, value, vendorId: vendorId, flags: flags);
      case AVPUTF8String:
        return AVPUTF8String(code, value, vendorId: vendorId, flags: flags);
      case AVPGrouped:
        return AVPGrouped(code, value, vendorId: vendorId, flags: flags);
      case AVPOctetString:
        return AVPOctetString(code, value, vendorId: vendorId, flags: flags);
      case AVPDiameterIdentity:
        return AVPDiameterIdentity(
          code,
          value,
          vendorId: vendorId,
          flags: flags,
        );
      case AVPAddress:
        return AVPAddress(code, value, vendorId: vendorId, flags: flags);
      case AVPEnumerated:
        return AVPEnumerated(code, value, vendorId: vendorId, flags: flags);
      default:
        return AVPOctetString(code, value, vendorId: vendorId, flags: flags);
    }
  }

  Uint8List _encodeData();
  void _decodeData(Uint8List data);

  int getPaddedLength() {
    final length = getLength();
    return (length + 3) & ~3;
  }

  int getLength() {
    return (vendorId != 0 ? 12 : 8) + _encodeData().length;
  }

  Uint8List encode() {
    final data = _encodeData();
    final length = (vendorId != 0 ? 12 : 8) + data.length;
    final paddedLength = (length + 3) & ~3;
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
    final avpDef =
        VENDOR_AVP_DICTIONARIES[vendorId]?[code] ?? AVP_DICTIONARY[code];
    final name = avpDef?.name ?? code.toString();
    return "AVP($name, Value: $value)";
  }
}

// --- Concrete AVP Type Implementations ---

class AVPUTF8String extends AVP {
  AVPUTF8String(super.code, super.value, {super.flags, super.vendorId});
  @override
  Uint8List _encodeData() => utf8.encode(value as String);
  @override
  void _decodeData(Uint8List data) => value = utf8.decode(data);
}

class AVPDiameterIdentity extends AVPUTF8String {
  AVPDiameterIdentity(super.code, super.value, {super.flags, super.vendorId});
}

class AVPOctetString extends AVP {
  AVPOctetString(super.code, super.value, {super.flags, super.vendorId});
  @override
  Uint8List _encodeData() => value as Uint8List;
  @override
  void _decodeData(Uint8List data) => value = data;
}

class AVPUnsigned32 extends AVP {
  AVPUnsigned32(super.code, super.value, {super.flags, super.vendorId});
  @override
  Uint8List _encodeData() =>
      (ByteData(4)..setUint32(0, value as int)).buffer.asUint8List();
  @override
  void _decodeData(Uint8List data) =>
      value = ByteData.view(data.buffer).getUint32(0);
}

class AVPUnsigned64 extends AVP {
  AVPUnsigned64(super.code, super.value, {super.flags, super.vendorId});
  @override
  Uint8List _encodeData() =>
      (ByteData(8)..setUint64(0, value as int)).buffer.asUint8List();
  @override
  void _decodeData(Uint8List data) =>
      value = ByteData.view(data.buffer).getUint64(0);
}

class AVPEnumerated extends AVPUnsigned32 {
  AVPEnumerated(super.code, super.value, {super.flags, super.vendorId});
}

class AVPAddress extends AVP {
  AVPAddress(super.code, super.value, {super.flags, super.vendorId});
  @override
  Uint8List _encodeData() {
    var rawAddress = InternetAddress(value).rawAddress;
    var data = Uint8List(2 + rawAddress.length);
    var byteData = ByteData.view(data.buffer);
    byteData.setUint16(
      0,
      rawAddress.length == 4 ? 1 : 2,
    ); // 1 for IPv4, 2 for IPv6
    data.setRange(2, data.length, rawAddress);
    return data;
  }

  @override
  void _decodeData(Uint8List data) {
    final addressFamily = ByteData.view(data.buffer).getUint16(0);
    value = InternetAddress.fromRawAddress(data.sublist(2)).address;
  }
}

class AVPGrouped extends AVP {
  AVPGrouped(super.code, super.value, {super.flags, super.vendorId});

  @override
  Uint8List _encodeData() {
    final builder = BytesBuilder();
    for (var avp in value as List<AVP>) {
      builder.add(avp.encode());
    }
    return builder.toBytes();
  }

  @override
  void _decodeData(Uint8List data) {
    List<AVP> decodedAvps = [];
    int offset = 0;
    while (offset < data.length) {
      final avp = AVP.decode(data.sublist(offset));
      decodedAvps.add(avp);
      offset += avp.getPaddedLength();
    }
    value = decodedAvps;
  }
}
