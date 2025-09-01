// // lib/applications/base/accounting.dart

// import '../../core/diameter_message2.dart';
// import '../../core/avp_dictionary.dart';

// /// Creates an Accounting-Request (ACR) message.
// /// See RFC 6733 Section 9.7.1 for details.
// class AccountingRequest extends DiameterMessage {
//   AccountingRequest._({
//     required int flags,
//     required int hopByHopId,
//     required int endToEndId,
//     required List<AVP> avpList,
//   }) : super(
//          length:
//              20 + avpList.fold(0, (sum, avp) => sum + avp.getPaddedLength()),
//          commandCode: CMD_ACCOUNTING,
//          applicationId: APP_ID_BASE_ACCOUNTING, // Using Base Accounting App
//          flags: flags,
//          hopByHopId: hopByHopId,
//          endToEndId: endToEndId,
//          version: 1,
//          avps: avpList,
//        );

//   /// Creates an ACR with Accounting-Record-Type set to START_RECORD (2).
//   factory AccountingRequest.start({
//     required String sessionId,
//     required String originHost,
//     required String originRealm,
//     required String destinationRealm,
//   }) {
//     return AccountingRequest._(
//       flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
//       hopByHopId: DiameterMessage.generateId(),
//       endToEndId: DiameterMessage.generateId(),
//       avpList: [
//         AVP.fromString(AVP_SESSION_ID, sessionId),
//         AVP.fromString(AVP_ORIGIN_HOST, originHost),
//         AVP.fromString(AVP_ORIGIN_REALM, originRealm),
//         AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
//         AVP.fromEnumerated(AVP_ACCOUNTING_RECORD_TYPE, 2), // START_RECORD
//         AVP.fromUnsigned32(AVP_ACCOUNTING_RECORD_NUMBER, 0),
//       ],
//     );
//   }

//   /// Creates an ACR with Accounting-Record-Type set to STOP_RECORD (4).
//   factory AccountingRequest.stop({
//     required String sessionId,
//     required String originHost,
//     required String originRealm,
//     required String destinationRealm,
//     required int recordNumber,
//   }) {
//     return AccountingRequest._(
//       flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
//       hopByHopId: DiameterMessage.generateId(),
//       endToEndId: DiameterMessage.generateId(),
//       avpList: [
//         AVP.fromString(AVP_SESSION_ID, sessionId),
//         AVP.fromString(AVP_ORIGIN_HOST, originHost),
//         AVP.fromString(AVP_ORIGIN_REALM, originRealm),
//         AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
//         AVP.fromEnumerated(AVP_ACCOUNTING_RECORD_TYPE, 4), // STOP_RECORD
//         AVP.fromUnsigned32(AVP_ACCOUNTING_RECORD_NUMBER, recordNumber),
//       ],
//     );
//   }
// }

// lib/applications/base/accounting.dart

import '../../core/avp_dictionary2.dart';
import '../../core/diameter_message3.dart';

/// Creates an Accounting-Request (ACR) message.
/// See RFC 6733 Section 9.7.1 for details.
class AccountingRequest extends DiameterMessage {
  /// Creates an ACR with Accounting-Record-Type set to START_RECORD.
  AccountingRequest.start({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
  }) : super.fromFields(
         commandCode: CMD_ACCOUNTING,
         applicationId: APP_ID_BASE_ACCOUNTING,
         flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_SESSION_ID, sessionId),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
           AVP.fromEnumerated(AVP_ACCOUNTING_RECORD_TYPE, 2), // START_RECORD
           AVP.fromUnsigned32(AVP_ACCOUNTING_RECORD_NUMBER, 0),
         ],
       );

  /// Creates an ACR with Accounting-Record-Type set to STOP_RECORD.
  AccountingRequest.stop({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required int recordNumber,
  }) : super.fromFields(
         commandCode: CMD_ACCOUNTING,
         applicationId: APP_ID_BASE_ACCOUNTING,
         flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_SESSION_ID, sessionId),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
           AVP.fromEnumerated(AVP_ACCOUNTING_RECORD_TYPE, 4), // STOP_RECORD
           AVP.fromUnsigned32(AVP_ACCOUNTING_RECORD_NUMBER, recordNumber),
         ],
       );
}

/// Creates an Accounting-Answer (ACA) message.
/// See RFC 6733 Section 9.7.2 for details.
class AccountingAnswer extends DiameterMessage {
  AccountingAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
  }) : super.fromFields(
         commandCode: CMD_ACCOUNTING,
         applicationId: request.applicationId,
         flags: 0, // This is an answer
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           request.getAVP(AVP_SESSION_ID)!,
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           request.getAVP(AVP_ACCOUNTING_RECORD_TYPE)!,
           request.getAVP(AVP_ACCOUNTING_RECORD_NUMBER)!,
         ],
       );
}
