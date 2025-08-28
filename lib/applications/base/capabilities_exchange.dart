// lib/applications/base/capabilities_exchange.dart

import 'dart:io';
import '../../core/diameter_message.dart';
import '../../core/avp_dictionary.dart';

// Class definition for CapabilitiesExchangeRequest remains the same...
class CapabilitiesExchangeRequest extends DiameterMessage {
  CapabilitiesExchangeRequest({
    required String originHost,
    required String originRealm,
    required String hostIpAddress,
    required int vendorId,
    required String productName,
    int firmwareRevision = 1,
  }) : super(
         length:
             20 +
             [
               AVP.fromString(AVP_ORIGIN_HOST, originHost),
               AVP.fromString(AVP_ORIGIN_REALM, originRealm),
               AVP(
                 code: AVP_HOST_IP_ADDRESS,
                 data: InternetAddress(hostIpAddress).rawAddress,
               ),
               AVP.fromUnsigned32(AVP_VENDOR_ID, vendorId),
               AVP.fromString(AVP_PRODUCT_NAME, productName),
               AVP.fromUnsigned32(AVP_FIRMWARE_REVISION, firmwareRevision),
               AVP.fromUnsigned32(
                 AVP_AUTH_APPLICATION_ID,
                 APP_ID_CREDIT_CONTROL,
               ),
             ].fold(0, (sum, avp) => sum + avp.getPaddedLength()),
         commandCode: CMD_CAPABILITIES_EXCHANGE,
         applicationId: 0,
         flags: DiameterMessage.FLAG_REQUEST,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         version: 1,
         avps: [
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP(
             code: AVP_HOST_IP_ADDRESS,
             data: InternetAddress(hostIpAddress).rawAddress,
           ),
           AVP.fromUnsigned32(AVP_VENDOR_ID, vendorId),
           AVP.fromString(AVP_PRODUCT_NAME, productName),
           AVP.fromUnsigned32(AVP_FIRMWARE_REVISION, firmwareRevision),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_CREDIT_CONTROL),
         ],
       );
}

class CapabilitiesExchangeAnswer extends DiameterMessage {
  CapabilitiesExchangeAnswer._({
    required int flags,
    required int hopByHopId,
    required int endToEndId,
    required List<AVP> avpList,
  }) : super(
         length:
             20 + avpList.fold(0, (sum, avp) => sum + avp.getPaddedLength()),
         commandCode: CMD_CAPABILITIES_EXCHANGE,
         applicationId: 0,
         flags: flags,
         hopByHopId: hopByHopId,
         endToEndId: endToEndId,
         version: 1,
         avps: avpList,
       );

  /// Creates a CEA in response to a received CER.
  // FIX: This now accepts the base DiameterMessage type
  factory CapabilitiesExchangeAnswer.fromRequest(
    DiameterMessage cer, {
    required int resultCode,
    required String originHost,
    required String originRealm,
    required String hostIpAddress,
    required int vendorId,
    required String productName,
  }) {
    return CapabilitiesExchangeAnswer._(
      flags: 0, // A CEA is not a request
      hopByHopId: cer.hopByHopId, // Must match the request
      endToEndId: cer.endToEndId, // Must match the request
      avpList: [
        AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
        AVP(
          code: AVP_HOST_IP_ADDRESS,
          data: InternetAddress(hostIpAddress).rawAddress,
        ),
        AVP.fromUnsigned32(AVP_VENDOR_ID, vendorId),
        AVP.fromString(AVP_PRODUCT_NAME, productName),
        AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_CREDIT_CONTROL),
      ],
    );
  }
}
