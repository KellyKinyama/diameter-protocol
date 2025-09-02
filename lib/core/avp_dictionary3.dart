// lib/core/avp_dictionary.dart

import 'diameter_avp.dart';

class AVPDefinition {
  final String name;
  final Type type;
  final bool isMandatory;

  AVPDefinition({
    required this.name,
    required this.type,
    this.isMandatory = false,
  });
}

// A true dictionary mapping AVP codes to their definitions.
// This drives the AVP.fromCode() factory.
final Map<int, AVPDefinition> AVP_DICTIONARY = {
  // Base Protocol AVPs
  1: AVPDefinition(name: "User-Name", type: AVPUTF8String),
  2: AVPDefinition(name: "User-Password", type: AVPOctetString),
  8: AVPDefinition(name: "Framed-IP-Address", type: AVPAddress),
  24: AVPDefinition(name: "State", type: AVPOctetString),
  257: AVPDefinition(name: "Host-IP-Address", type: AVPAddress),
  258: AVPDefinition(
    name: "Auth-Application-Id",
    type: AVPUnsigned32,
    isMandatory: true,
  ),
  259: AVPDefinition(name: "Acct-Application-Id", type: AVPUnsigned32),
  263: AVPDefinition(
    name: "Session-Id",
    type: AVPUTF8String,
    isMandatory: true,
  ),
  264: AVPDefinition(
    name: "Origin-Host",
    type: AVPDiameterIdentity,
    isMandatory: true,
  ),
  265: AVPDefinition(name: "Supported-Vendor-Id", type: AVPUnsigned32),
  266: AVPDefinition(name: "Vendor-Id", type: AVPUnsigned32),
  267: AVPDefinition(name: "Firmware-Revision", type: AVPUnsigned32),
  268: AVPDefinition(
    name: "Result-Code",
    type: AVPUnsigned32,
    isMandatory: true,
  ),
  269: AVPDefinition(name: "Product-Name", type: AVPUTF8String),
  273: AVPDefinition(name: "Disconnect-Cause", type: AVPEnumerated),
  274: AVPDefinition(name: "Auth-Request-Type", type: AVPEnumerated),
  278: AVPDefinition(name: "Origin-State-Id", type: AVPUnsigned32),
  282: AVPDefinition(name: "Route-Record", type: AVPDiameterIdentity),
  283: AVPDefinition(
    name: "Destination-Realm",
    type: AVPDiameterIdentity,
    isMandatory: true,
  ),
  285: AVPDefinition(name: "Re-Auth-Request-Type", type: AVPEnumerated),
  293: AVPDefinition(name: "Destination-Host", type: AVPDiameterIdentity),
  295: AVPDefinition(name: "Termination-Cause", type: AVPEnumerated),
  296: AVPDefinition(
    name: "Origin-Realm",
    type: AVPDiameterIdentity,
    isMandatory: true,
  ),
  298: AVPDefinition(name: "Experimental-Result-Code", type: AVPUnsigned32),

  // Credit-Control AVPs
  415: AVPDefinition(
    name: "CC-Request-Number",
    type: AVPUnsigned32,
    isMandatory: true,
  ),
  416: AVPDefinition(
    name: "CC-Request-Type",
    type: AVPEnumerated,
    isMandatory: true,
  ),
  421: AVPDefinition(name: "CC-Total-Octets", type: AVPUnsigned64),
  431: AVPDefinition(name: "Granted-Service-Unit", type: AVPGrouped),
  430: AVPDefinition(name: "Final-Unit-Indication", type: AVPGrouped),
  444: AVPDefinition(name: "Subscription-Id-Data", type: AVPUTF8String),
  443: AVPDefinition(name: "Subscription-Id", type: AVPGrouped),
  446: AVPDefinition(name: "Used-Service-Unit", type: AVPGrouped),
  449: AVPDefinition(name: "Final-Unit-Action", type: AVPEnumerated),
  450: AVPDefinition(name: "Subscription-Id-Type", type: AVPEnumerated),
  461: AVPDefinition(name: "Service-Context-Id", type: AVPUTF8String),

  480: AVPDefinition(name: "Accounting-Record-Type", type: AVPEnumerated),
  485: AVPDefinition(name: "Accounting-Record-Number", type: AVPUnsigned32),
};

// Vendor-specific dictionaries
final Map<int, Map<int, AVPDefinition>> VENDOR_AVP_DICTIONARIES = {
  10415: {
    // 3GPP
    1032: AVPDefinition(name: "RAT-Type", type: AVPEnumerated),
    1001: AVPDefinition(name: "Charging-Rule-Install", type: AVPGrouped),
    1003: AVPDefinition(name: "Charging-Rule-Definition", type: AVPGrouped),
    1005: AVPDefinition(name: "Charging-Rule-Name", type: AVPOctetString),
    1016: AVPDefinition(name: "QoS-Information", type: AVPGrouped),
    1027: AVPDefinition(name: "IP-CAN-Type", type: AVPEnumerated),
    1028: AVPDefinition(name: "QoS-Class-Identifier", type: AVPEnumerated),
    1400: AVPDefinition(name: "Subscription-Data", type: AVPGrouped),
    1405: AVPDefinition(name: "ULR-Flags", type: AVPUnsigned32),
    1407: AVPDefinition(name: "Visited-PLMN-Id", type: AVPOctetString),
    1408: AVPDefinition(
      name: "Requested-EUTRAN-Authentication-Info",
      type: AVPGrouped,
    ),
    1409: AVPDefinition(
      name: "Number-Of-Requested-Vectors",
      type: AVPUnsigned32,
    ),
    1410: AVPDefinition(
      name: "Immediate-Response-Preferred",
      type: AVPEnumerated,
    ),
    1413: AVPDefinition(name: "Authentication-Info", type: AVPGrouped),
    1414: AVPDefinition(name: "E-UTRAN-Vector", type: AVPGrouped),
    1415: AVPDefinition(name: "RAND", type: AVPOctetString),
    1416: AVPDefinition(name: "XRES", type: AVPOctetString),
    1417: AVPDefinition(name: "AUTN", type: AVPOctetString),
    1418: AVPDefinition(name: "KASME", type: AVPOctetString),
    1424: AVPDefinition(name: "Access-Restriction-Data", type: AVPUnsigned32),
  },
};
