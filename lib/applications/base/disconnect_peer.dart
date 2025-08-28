// lib/applications/base/disconnect_peer.dart

// lib/applications/base/disconnect_peer.dart

import '../../core/diameter_message.dart';
import '../../core/avp_dictionary2.dart';

/// Creates a Disconnect-Peer-Request (DPR) message.
/// See RFC 6733 Section 5.4.1 for details.
class DisconnectPeerRequest extends DiameterMessage {
  DisconnectPeerRequest({
    required String originHost,
    required String originRealm,
    int disconnectCause = 0, // 0 = REBOOTING
  }) : super(
         // Calculate length and call the main super() constructor
         length:
             20 +
             [
               AVP.fromString(AVP_ORIGIN_HOST, originHost),
               AVP.fromString(AVP_ORIGIN_REALM, originRealm),
               AVP.fromEnumerated(AVP_DISCONNECT_CAUSE, disconnectCause),
             ].fold(0, (sum, avp) => sum + avp.getPaddedLength()),
         commandCode: CMD_DISCONNECT_PEER,
         applicationId: 0,
         flags: DiameterMessage.FLAG_REQUEST,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         version: 1,
         avps: [
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromEnumerated(AVP_DISCONNECT_CAUSE, disconnectCause),
         ],
       );
}
