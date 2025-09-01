// lib/applications/sip/sip.dart

import '../../core/avp_dictionary2.dart';
import '../../core/diameter_message3.dart';

class UserAuthorizationRequest extends DiameterMessage {
  UserAuthorizationRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required String sipAor,
  }) : super.fromFields(
         commandCode: CMD_USER_AUTHORIZATION,
         applicationId: APP_ID_SIP,
         flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_SESSION_ID, sessionId),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_SIP),
           AVP.fromEnumerated(AVP_STATE, 0), // Auth-Session-State
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
           AVP.fromString(AVP_SIP_AOR, sipAor),
         ],
       );
}

class UserAuthorizationAnswer extends DiameterMessage {
  UserAuthorizationAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
    String? sipServerUri,
  }) : super.fromFields(
         commandCode: CMD_USER_AUTHORIZATION,
         applicationId: request.applicationId,
         flags: 0, // Answer
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           request.getAVP(AVP_SESSION_ID)!,
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           request.getAVP(AVP_AUTH_APPLICATION_ID)!,
           request.getAVP(AVP_STATE)!,
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           if (sipServerUri != null)
             AVP.fromString(AVP_SIP_SERVER_URI, sipServerUri),
         ],
       );
}

// Stubs for other SIP commands
class ServerAssignmentAnswer extends DiameterMessage {
  ServerAssignmentAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
  }) : super.fromFields(
         commandCode: CMD_SERVER_ASSIGNMENT,
         applicationId: request.applicationId,
         flags: 0,
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           request.getAVP(AVP_SESSION_ID)!,
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
         ],
       );
}

class LocationInfoAnswer extends DiameterMessage {
  LocationInfoAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
    String? sipServerUri,
  }) : super.fromFields(
         commandCode: CMD_LOCATION_INFO,
         applicationId: request.applicationId,
         flags: 0,
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           request.getAVP(AVP_SESSION_ID)!,
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           if (sipServerUri != null)
             AVP.fromString(AVP_SIP_SERVER_URI, sipServerUri),
         ],
       );
}

class MultimediaAuthAnswer extends DiameterMessage {
  MultimediaAuthAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
  }) : super.fromFields(
         commandCode: CMD_MULTIMEDIA_AUTH,
         applicationId: request.applicationId,
         flags: 0,
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           request.getAVP(AVP_SESSION_ID)!,
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
         ],
       );
}
