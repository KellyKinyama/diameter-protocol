// // lib/applications/base/disconnect_peer.dart

// import '../../core/diameter_message3.dart';
// import '../../core/avp_dictionary2.dart';

// class DisconnectPeerRequest extends DiameterMessage {
//   DisconnectPeerRequest({
//     required String originHost,
//     required String originRealm,
//     int disconnectCause = 0, // 0 = REBOOTING
//   }) : super(
//          length:
//              20 +
//              [
//                AVP.fromString(AVP_ORIGIN_HOST, originHost),
//                AVP.fromString(AVP_ORIGIN_REALM, originRealm),
//                AVP.fromEnumerated(AVP_DISCONNECT_CAUSE, disconnectCause),
//              ].fold(0, (sum, avp) => sum + avp.getPaddedLength()),
//          commandCode: CMD_DISCONNECT_PEER,
//          applicationId: 0,
//          flags: DiameterMessage.FLAG_REQUEST,
//          hopByHopId: DiameterMessage.generateId(),
//          endToEndId: DiameterMessage.generateId(),
//          version: 1,
//          avps: [
//            AVP.fromString(AVP_ORIGIN_HOST, originHost),
//            AVP.fromString(AVP_ORIGIN_REALM, originRealm),
//            AVP.fromEnumerated(AVP_DISCONNECT_CAUSE, disconnectCause),
//          ],
//        );
// }

// lib/applications/base/disconnect_peer.dart

import '../../core/avp_dictionary.dart';
import '../../core/diameter_message3.dart';

/// Creates a Disconnect-Peer-Request (DPR) message.
/// See RFC 6733 Section 5.4.1 for details.
class DisconnectPeerRequest extends DiameterMessage {
  DisconnectPeerRequest({
    required String originHost,
    required String originRealm,
    int disconnectCause = 0, // 0 = REBOOTING
  }) : super.fromFields(
         commandCode: CMD_DISCONNECT_PEER,
         applicationId: 0, // Base protocol
         flags: DiameterMessage.FLAG_REQUEST,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromEnumerated(AVP_DISCONNECT_CAUSE, disconnectCause),
         ],
       );
}

/// Creates a Disconnect-Peer-Answer (DPA) message.
/// See RFC 6733 Section 5.4.2 for details.
class DisconnectPeerAnswer extends DiameterMessage {
  DisconnectPeerAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
  }) : super.fromFields(
         commandCode: CMD_DISCONNECT_PEER,
         applicationId: 0, // Base protocol
         flags: 0, // This is an answer
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
         ],
       );
}
