// lib/applications/base/session_management.dart

import '../../core/avp_dictionary.dart';
import '../../core/diameter_avp.dart';
import '../../core/message_generator.dart';

class SessionTerminationRequest extends MessageGenerator {
  String sessionId;
  int authApplicationId;
  int terminationCause;

  SessionTerminationRequest({
    required this.sessionId,
    required this.authApplicationId,
    this.terminationCause = 1, // 1 = DIAMETER_LOGOUT
  });

  @override
  List<AVP> toAVPs() {
    return [
      AVP.fromValue(AVP_SESSION_ID, sessionId),
      AVP.fromValue(AVP_AUTH_APPLICATION_ID, authApplicationId),
      AVP.fromValue(AVP_TERMINATION_CAUSE, terminationCause),
    ];
  }
}

class SessionTerminationAnswer extends MessageGenerator {
  String sessionId;

  SessionTerminationAnswer({required this.sessionId});

  @override
  List<AVP> toAVPs() {
    return [AVP.fromValue(AVP_SESSION_ID, sessionId)];
  }
}
