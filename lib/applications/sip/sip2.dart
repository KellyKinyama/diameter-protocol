// lib/applications/sip/sip.dart

import '../../core/diameter_avp.dart';
import '../../core/message_generator.dart';
import '../../core/avp_dictionary.dart';

class SipAuthDataItem extends MessageGenerator {
  String sipAuthenticationScheme;
  SipAuthDataItem({required this.sipAuthenticationScheme});

  @override
  List<AVP> toAVPs() {
    return [
      AVP.fromValue(378, sipAuthenticationScheme, vendorId: 10415) // SIP-Authentication-Scheme
    ];
  }
}

class UserAuthorizationRequest extends MessageGenerator {
  String sessionId;
  String userName;
  SipAuthDataItem sipAuthDataItem;

  UserAuthorizationRequest({
    required this.sessionId,
    required this.userName,
    required this.sipAuthDataItem,
  });

  @override
  List<AVP> toAVPs() {
    return [
      AVP.fromValue(AVP_SESSION_ID, sessionId),
      AVP.fromValue(AVP_USER_NAME, userName),
      AVP.fromValue(376, sipAuthDataItem.toAVPs(), vendorId: 10415), // SIP-Auth-Data-Item
    ];
  }
}

class ServerAssignmentRequest extends MessageGenerator {
  String sessionId;
  String userName;
  int serverAssignmentType;

  ServerAssignmentRequest({
    required this.sessionId,
    required this.userName,
    required this.serverAssignmentType,
  });

  @override
  List<AVP> toAVPs() {
    return [
      AVP.fromValue(AVP_SESSION_ID, sessionId),
      AVP.fromValue(AVP_USER_NAME, userName),
      AVP.fromValue(370, serverAssignmentType, vendorId: 10415) // Server-Assignment-Type
    ];
  }
}