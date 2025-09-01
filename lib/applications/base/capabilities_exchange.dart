// lib/applications/base/capabilities_exchange.dart

import 'dart:io';
import '../../core/diameter_message3.dart';
import '../../core/avp_dictionary2.dart';

// class CapabilitiesExchangeRequest extends DiameterMessage {
//   CapabilitiesExchangeRequest({
//     required String originHost,
//     required String originRealm,
//     required String hostIpAddress,
//     required int vendorId,
//     required String productName,
//     int firmwareRevision = 1,
//   }) : super(
//          length:
//              20 +
//              [
//                AVP.fromString(AVP_ORIGIN_HOST, originHost),
//                AVP.fromString(AVP_ORIGIN_REALM, originRealm),
//                AVP.fromAddress(AVP_HOST_IP_ADDRESS, hostIpAddress),
//                AVP.fromUnsigned32(AVP_VENDOR_ID, vendorId),
//                AVP.fromString(AVP_PRODUCT_NAME, productName),
//                AVP.fromUnsigned32(AVP_FIRMWARE_REVISION, firmwareRevision),
//                AVP.fromUnsigned32(
//                  AVP_AUTH_APPLICATION_ID,
//                  APP_ID_CREDIT_CONTROL,
//                ),
//              ].fold(0, (sum, avp) => sum + avp.getPaddedLength()),
//          commandCode: CMD_CAPABILITIES_EXCHANGE,
//          applicationId: 0,
//          flags: DiameterMessage.FLAG_REQUEST,
//          hopByHopId: DiameterMessage.generateId(),
//          endToEndId: DiameterMessage.generateId(),
//          version: 1,
//          avps: [
//            AVP.fromString(AVP_ORIGIN_HOST, originHost),
//            AVP.fromString(AVP_ORIGIN_REALM, originRealm),
//            AVP.fromAddress(AVP_HOST_IP_ADDRESS, hostIpAddress),
//            AVP.fromUnsigned32(AVP_VENDOR_ID, vendorId),
//            AVP.fromString(AVP_PRODUCT_NAME, productName),
//            AVP.fromUnsigned32(AVP_FIRMWARE_REVISION, firmwareRevision),
//            AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_CREDIT_CONTROL),
//          ],
//        );
// }

// class CapabilitiesExchangeAnswer extends DiameterMessage {
//   CapabilitiesExchangeAnswer._({
//     required int flags,
//     required int hopByHopId,
//     required int endToEndId,
//     required List<AVP> avpList,
//   }) : super(
//          length:
//              20 + avpList.fold(0, (sum, avp) => sum + avp.getPaddedLength()),
//          commandCode: CMD_CAPABILITIES_EXCHANGE,
//          applicationId: 0,
//          flags: flags,
//          hopByHopId: hopByHopId,
//          endToEndId: endToEndId,
//          version: 1,
//          avps: avpList,
//        );

//   factory CapabilitiesExchangeAnswer.fromRequest(
//     DiameterMessage cer, {
//     required int resultCode,
//     required String originHost,
//     required String originRealm,
//     required String hostIpAddress,
//     required int vendorId,
//     required String productName,
//   }) {
//     return CapabilitiesExchangeAnswer._(
//       flags: 0,
//       hopByHopId: cer.hopByHopId,
//       endToEndId: cer.endToEndId,
//       avpList: [
//         AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
//         AVP.fromString(AVP_ORIGIN_HOST, originHost),
//         AVP.fromString(AVP_ORIGIN_REALM, originRealm),
//         AVP.fromAddress(AVP_HOST_IP_ADDRESS, hostIpAddress),
//         AVP.fromUnsigned32(AVP_VENDOR_ID, vendorId),
//         AVP.fromString(AVP_PRODUCT_NAME, productName),
//         AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_CREDIT_CONTROL),
//       ],
//     );
//   }
// }

// lib/applications/base/capabilities_exchange.dart

// import '../../core/avp_dictionary.dart';
// import '../../core/diameter_message2.dart';

/// Creates a Capabilities-Exchange-Request (CER) message.
/// See RFC 6733 Section 5.3.1 for details.
class CapabilitiesExchangeRequest extends DiameterMessage {
  CapabilitiesExchangeRequest({
    required String originHost,
    required String originRealm,
    required String hostIpAddress,
    required int vendorId,
    required String productName,
    int firmwareRevision = 1,
    List<int> authApplicationIds = const [],
    List<int> acctApplicationIds = const [],
    List<int> supportedVendorIds = const [],
  }) : super.fromFields(
         commandCode: CMD_CAPABILITIES_EXCHANGE,
         applicationId: 0, // Base protocol
         flags: DiameterMessage.FLAG_REQUEST,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromAddress(AVP_HOST_IP_ADDRESS, hostIpAddress),
           AVP.fromUnsigned32(AVP_VENDOR_ID, vendorId),
           AVP.fromString(AVP_PRODUCT_NAME, productName),
           AVP.fromUnsigned32(AVP_FIRMWARE_REVISION, firmwareRevision),
           ...authApplicationIds.map(
             (id) => AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, id),
           ),
           ...acctApplicationIds.map(
             (id) => AVP.fromUnsigned32(AVP_ACCT_APPLICATION_ID, id),
           ),
           ...supportedVendorIds.map(
             (id) => AVP.fromUnsigned32(AVP_SUPPORTED_VENDOR_ID, id),
           ),
         ],
       );
}

/// Creates a Capabilities-Exchange-Answer (CEA) message.
/// See RFC 6733 Section 5.3.2 for details.
class CapabilitiesExchangeAnswer extends DiameterMessage {
  CapabilitiesExchangeAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
    required String hostIpAddress,
    required int vendorId,
    required String productName,
    int firmwareRevision = 1,
    List<int> authApplicationIds = const [],
    List<int> acctApplicationIds = const [],
    List<int> supportedVendorIds = const [],
  }) : super.fromFields(
         commandCode: CMD_CAPABILITIES_EXCHANGE,
         applicationId: 0, // Base protocol
         flags: 0, // This is an answer
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromAddress(AVP_HOST_IP_ADDRESS, hostIpAddress),
           AVP.fromUnsigned32(AVP_VENDOR_ID, vendorId),
           AVP.fromString(AVP_PRODUCT_NAME, productName),
           AVP.fromUnsigned32(AVP_FIRMWARE_REVISION, firmwareRevision),
           // A server should typically advertise all its supported apps
           ...authApplicationIds.map(
             (id) => AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, id),
           ),
           ...acctApplicationIds.map(
             (id) => AVP.fromUnsigned32(AVP_ACCT_APPLICATION_ID, id),
           ),
           ...supportedVendorIds.map(
             (id) => AVP.fromUnsigned32(AVP_SUPPORTED_VENDOR_ID, id),
           ),
         ],
       );
}
