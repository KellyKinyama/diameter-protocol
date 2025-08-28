// lib/applications/base/watchdog.dart

import '../../core/diameter_message2.dart';
import '../../core/avp_dictionary3.dart';

class DeviceWatchdogRequest extends DiameterMessage {
  DeviceWatchdogRequest({
    required String originHost,
    required String originRealm,
  }) : super(
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
