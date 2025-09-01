// lib/applications/base/watchdog.dart

import '../../core/avp_dictionary2.dart';
import '../../core/diameter_message3.dart';

/// Creates a Device-Watchdog-Request (DWR) message.
/// See RFC 6733 Section 5.5.1 for details.
class DeviceWatchdogRequest extends DiameterMessage {
  DeviceWatchdogRequest({
    required String originHost,
    required String originRealm,
  }) : super.fromFields(
         commandCode: CMD_DEVICE_WATCHDOG,
         applicationId: 0, // Base protocol
         flags: DiameterMessage.FLAG_REQUEST,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           // Origin-State-Id is optional but recommended
           AVP.fromUnsigned32(
             AVP_ORIGIN_STATE_ID,
             DateTime.now().millisecondsSinceEpoch ~/ 1000,
           ),
         ],
       );
}

/// Creates a Device-Watchdog-Answer (DWA) message.
/// See RFC 6733 Section 5.5.2 for details.
class DeviceWatchdogAnswer extends DiameterMessage {
  DeviceWatchdogAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
  }) : super.fromFields(
         commandCode: CMD_DEVICE_WATCHDOG,
         applicationId: 0, // Base protocol
         flags: 0, // This is an answer
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           // Origin-State-Id is optional but recommended
           AVP.fromUnsigned32(
             AVP_ORIGIN_STATE_ID,
             DateTime.now().millisecondsSinceEpoch ~/ 1000,
           ),
         ],
       );
}
