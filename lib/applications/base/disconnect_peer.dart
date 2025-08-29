// lib/applications/base/disconnect_peer.dart

import '../../core/diameter_message2.dart';
import '../../core/avp_dictionary.dart';

class DisconnectPeerRequest extends DiameterMessage {
  DisconnectPeerRequest({
    required String originHost,
    required String originRealm,
    int disconnectCause = 0, // 0 = REBOOTING
  }) : super(
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
