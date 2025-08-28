// lib/applications/base/watchdog.dart

import '../../core/diameter_message.dart';
import '../../core/avp_dictionary.dart';

/// Creates a Device-Watchdog-Request (DWR) message.
/// See RFC 6733 Section 5.5.1 for details.
class DeviceWatchdogRequest extends DiameterMessage {
  DeviceWatchdogRequest({
    required String originHost,
    required String originRealm,
  }) : super(
         // Calculate length before calling the main super() constructor
         length:
             20 +
             [
               AVP.fromString(AVP_ORIGIN_HOST, originHost),
               AVP.fromString(AVP_ORIGIN_REALM, originRealm),
             ].fold(0, (sum, avp) => sum + avp.getPaddedLength()),
         commandCode: CMD_DEVICE_WATCHDOG,
         applicationId: 0,
         flags: DiameterMessage.FLAG_REQUEST,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         version: 1,
         avps: [
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
         ],
       );
}
