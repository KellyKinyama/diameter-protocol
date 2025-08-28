// lib/core/avp_dictionary.dart

// AVP Codes from RFC 6733 and other standards
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
const AVP_RE_AUTH_REQUEST_TYPE = 285; // New

// Accounting AVPs (Section 9.8)
const AVP_ACCOUNTING_RECORD_TYPE = 480; // New
const AVP_ACCOUNTING_RECORD_NUMBER = 485; // New
const AVP_ACCT_INTERIM_INTERVAL = 85; // New

// Credit-Control Application AVPs (RFC 4006)
const AVP_CC_REQUEST_TYPE = 416;
const AVP_CC_REQUEST_NUMBER = 415;
const AVP_USED_SERVICE_UNIT = 446;

// --- Command Codes from RFC 6733 ---
const CMD_CAPABILITIES_EXCHANGE = 257;
const CMD_DEVICE_WATCHDOG = 280;
const CMD_DISCONNECT_PEER = 282;
const CMD_RE_AUTH = 258; // Renamed for consistency
const CMD_SESSION_TERMINATION = 275;
const CMD_ABORT_SESSION = 274;
const CMD_ACCOUNTING = 271;

// --- Application Specific Command Codes ---
const CMD_CREDIT_CONTROL = 272;

// --- Application IDs ---
const APP_ID_BASE_ACCOUNTING = 3;
const APP_ID_CREDIT_CONTROL = 4;

// lib/core/avp_dictionary.dart

// ... (existing AVP codes)

// --- Gy Interface / Credit-Control AVPs ---
const AVP_REQUESTED_SERVICE_UNIT = 437; // Grouped
const AVP_GRANTED_SERVICE_UNIT = 417; // Grouped
const AVP_CC_TOTAL_OCTETS = 421;
const AVP_CC_INPUT_OCTETS = 412;
const AVP_CC_OUTPUT_OCTETS = 414;

// ... (rest of the file is unchanged)
