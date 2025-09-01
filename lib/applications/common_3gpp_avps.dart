import '../core/diameter_message.dart';
import '../core/avp_dictionary.dart';
import 'dart:typed_data';

// --- 3GPP Vendor ID ---
const VENDOR_ID_3GPP = 10415;

// --- AVP Codes ---
const AVP_SESSION_ID = 263;
const AVP_ORIGIN_HOST = 264;
const AVP_ORIGIN_REALM = 296;
const AVP_DESTINATION_REALM = 283;
const AVP_DESTINATION_HOST = 293;
const AVP_AUTH_APPLICATION_ID = 258;
const AVP_ACCT_APPLICATION_ID = 259;
const AVP_RESULT_CODE = 268;
const AVP_PRODUCT_NAME = 269;
const AVP_VENDOR_ID = 266;
const AVP_FIRMWARE_REVISION = 267;
const AVP_HOST_IP_ADDRESS = 257;
const AVP_SUPPORTED_VENDOR_ID = 265;
const AVP_TERMINATION_CAUSE = 295;
const AVP_USER_NAME = 1;
const AVP_ORIGIN_STATE_ID = 278;
const AVP_ROUTE_RECORD = 282;
const AVP_DISCONNECT_CAUSE = 273;
const AVP_RE_AUTH_REQUEST_TYPE = 285;
const AVP_ACCOUNTING_RECORD_TYPE = 480;
const AVP_ACCOUNTING_RECORD_NUMBER = 485;
const AVP_ACCT_INTERIM_INTERVAL = 85;
const AVP_FAILED_AVP = 279;
const AVP_PROXY_INFO = 284;
const AVP_SERVICE_CONTEXT_ID = 461;

// --- Credit-Control AVPs (RFC 4006) ---
const AVP_CC_REQUEST_TYPE = 416;
const AVP_CC_REQUEST_NUMBER = 415;
const AVP_USED_SERVICE_UNIT = 446;
const AVP_REQUESTED_SERVICE_UNIT = 437;
const AVP_GRANTED_SERVICE_UNIT = 431;
const AVP_CC_TOTAL_OCTETS = 421;
const AVP_CC_INPUT_OCTETS = 412;
const AVP_CC_OUTPUT_OCTETS = 414;
const AVP_MULTIPLE_SERVICES_CREDIT_CONTROL = 456;

// --- 3GPP AVP Codes from examples ---
const AVP_SERVICE_INFORMATION = 873;
const AVP_IMS_INFORMATION = 876;
const AVP_PS_INFORMATION = 874;
const AVP_EVENT_TYPE = 823;
const AVP_SIP_METHOD = 824;
const AVP_EVENT = 825;
const AVP_TIME_STAMPS = 833;
const AVP_SIP_REQUEST_TIMESTAMP = 834;
const AVP_SIP_RESPONSE_TIMESTAMP = 835;
const AVP_CALLING_PARTY_ADDRESS = 831;

// --- Command Codes ---
const CMD_CAPABILITIES_EXCHANGE = 257;
const CMD_DEVICE_WATCHDOG = 280;
const CMD_DISCONNECT_PEER = 282;
const CMD_RE_AUTH = 258;
const CMD_SESSION_TERMINATION = 275;
const CMD_ABORT_SESSION = 274;
const CMD_ACCOUNTING = 271;
const CMD_CREDIT_CONTROL = 272;

// --- Application IDs ---
const APP_ID_BASE_ACCOUNTING = 3;
const APP_ID_CREDIT_CONTROL = 4;
const APP_ID_S6A = 16777251;

// lib/applications/common_3gpp_avps.dart

/// Helper class for the 3GPP Service-Information AVP (Grouped)
class ServiceInformation extends AVP {
  ServiceInformation({
    PsInformation? psInformation,
    ImsInformation? imsInformation,
    // Add other info types like MMS, LCS, etc. here
  }) : super(
         code: AVP_SERVICE_INFORMATION,
         vendorId: VENDOR_ID_3GPP,
         flags: AVP.FLAG_VENDOR | AVP.FLAG_MANDATORY,
         avps: [
           if (psInformation != null) psInformation,
           if (imsInformation != null) imsInformation,
           // Add others to the list
         ],
       );
}

/// Helper class for the 3GPP PS-Information AVP (Grouped)
class PsInformation extends AVP {
  PsInformation({
    required Uint8List chargingId,
    // Add other PS-Information fields as needed
  }) : super(
         code: AVP_PS_INFORMATION,
         vendorId: VENDOR_ID_3GPP,
         flags: AVP.FLAG_VENDOR | AVP.FLAG_MANDATORY,
         avps: [
           AVP(
             code: AVP_TGPP_CHARGING_ID,
             vendorId: VENDOR_ID_3GPP,
             data: chargingId,
           ),
           // Add other AVPs here
         ],
       );
}

/// Helper class for the 3GPP IMS-Information AVP (Grouped)
class ImsInformation extends AVP {
  ImsInformation({
    EventType? eventType,
    TimeStamps? timeStamps,
    String? callingPartyAddress,
    // Add other IMS-Information fields as needed
  }) : super(
         code: AVP_IMS_INFORMATION,
         vendorId: VENDOR_ID_3GPP,
         flags: AVP.FLAG_VENDOR | AVP.FLAG_MANDATORY,
         avps: [
           if (eventType != null) eventType,
           if (timeStamps != null) timeStamps,
           if (callingPartyAddress != null)
             AVP.fromString(AVP_CALLING_PARTY_ADDRESS, callingPartyAddress)
               ..vendorId = VENDOR_ID_3GPP,
         ],
       );
}

/// Helper class for the Event-Type AVP (Grouped)
class EventType extends AVP {
  EventType({String? sipMethod, String? event})
    : super.fromGrouped(AVP_EVENT_TYPE, [
        if (sipMethod != null) AVP.fromString(AVP_SIP_METHOD, sipMethod),
        if (event != null) AVP.fromString(AVP_EVENT, event),
      ]) {
    super.vendorId = VENDOR_ID_3GPP;
  }
}

/// Helper class for the Time-Stamps AVP (Grouped)
class TimeStamps extends AVP {
  TimeStamps({DateTime? sipRequestTimestamp, DateTime? sipResponseTimestamp})
    : super.fromGrouped(AVP_TIME_STAMPS, [
        if (sipRequestTimestamp != null)
          AVP.fromDateTime(AVP_SIP_REQUEST_TIMESTAMP, sipRequestTimestamp),
        if (sipResponseTimestamp != null)
          AVP.fromDateTime(AVP_SIP_RESPONSE_TIMESTAMP, sipResponseTimestamp),
      ]) {
    super.vendorId = VENDOR_ID_3GPP;
  }
}
