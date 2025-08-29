// lib/applications/base/capabilities_exchange.dart

import 'dart:io';
import '../../core/diameter_message2.dart';
import '../../core/avp_dictionary.dart';

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
               AVP.fromAddress(AVP_HOST_IP_ADDRESS, hostIpAddress),
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
           AVP.fromAddress(AVP_HOST_IP_ADDRESS, hostIpAddress),
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
      flags: 0,
      hopByHopId: cer.hopByHopId,
      endToEndId: cer.endToEndId,
      avpList: [
        AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
        AVP.fromAddress(AVP_HOST_IP_ADDRESS, hostIpAddress),
        AVP.fromUnsigned32(AVP_VENDOR_ID, vendorId),
        AVP.fromString(AVP_PRODUCT_NAME, productName),
        AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_CREDIT_CONTROL),
      ],
    );
  }
}
