// lib/applications/base/watchdog.dart

import '../../core/avp_dictionary.dart';
import '../../core/diameter_avp.dart';
import '../../core/message_generator.dart';

class DeviceWatchdogRequest extends MessageGenerator {
  // No specific AVPs needed for the request besides the standard ones
  @override
  List<AVP> toAVPs() {
    return [];
  }
}

class DeviceWatchdogAnswer extends MessageGenerator {
  // No specific AVPs needed for the answer besides the standard ones
  @override
  List<AVP> toAVPs() {
    return [];
  }
}
