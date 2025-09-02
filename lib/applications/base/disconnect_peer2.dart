// lib/applications/base/disconnect_peer.dart

import '../../core/avp_dictionary.dart';
import '../../core/diameter_avp.dart';
import '../../core/message_generator.dart';

class DisconnectPeerRequest extends MessageGenerator {
  int disconnectCause;

  DisconnectPeerRequest({this.disconnectCause = 0}); // 0 = REBOOTING

  @override
  List<AVP> toAVPs() {
    return [
      AVP.fromValue(AVP_DISCONNECT_CAUSE, disconnectCause),
    ];
  }
}

class DisconnectPeerAnswer extends MessageGenerator {
  // No specific AVPs needed for the answer besides the standard ones
  @override
  List<AVP> toAVPs() {
    return [];
  }
}