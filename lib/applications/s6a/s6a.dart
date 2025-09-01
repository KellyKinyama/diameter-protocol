// lib/applications/s6a/s6a.dart

import '../../core/avp_dictionary2.dart';
import '../../core/diameter_message3.dart';

/// Creates an S6a Update-Location-Request (ULR) message.
class UpdateLocationRequest extends DiameterMessage {
  UpdateLocationRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required String imsi, // User-Name AVP carries the IMSI
    required String visitedPlmnId,
  }) : super.fromFields(
         commandCode: CMD_UPDATE_LOCATION,
         applicationId: APP_ID_3GPP_S6A,
         flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_SESSION_ID, sessionId),
           AVP.fromUnsigned32(AVP_VENDOR_ID, VENDOR_ID_3GPP),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_3GPP_S6A),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
           AVP.fromString(AVP_USER_NAME, imsi),
           AVP.fromString(
             AVP_VISITED_PLMN_ID,
             visitedPlmnId,
             vendorId: VENDOR_ID_3GPP,
           ),
           AVP.fromUnsigned32(
             AVP_ULR_FLAGS,
             1,
             vendorId: VENDOR_ID_3GPP,
           ), // Single-Registration-Indication
           AVP.fromUnsigned32(
             AVP_RAT_TYPE,
             1004,
             vendorId: VENDOR_ID_3GPP,
           ), // EUTRAN
         ],
       );
}

/// Creates an S6a Update-Location-Answer (ULA) message.
class UpdateLocationAnswer extends DiameterMessage {
  UpdateLocationAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
  }) : super.fromFields(
         commandCode: CMD_UPDATE_LOCATION,
         applicationId: request.applicationId,
         flags: DiameterMessage.FLAG_PROXYABLE, // Answer
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           request.getAVP(AVP_SESSION_ID)!,
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromUnsigned32(AVP_VENDOR_ID, VENDOR_ID_3GPP),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_3GPP_S6A),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           // In a real HSS, this would be populated with the user's full subscription profile
           AVP.fromGrouped(AVP_SUBSCRIPTION_DATA, [], vendorId: VENDOR_ID_3GPP),
         ],
       );
}

/// Creates an S6a Authentication-Information-Request (AIR) message.
class AuthenticationInformationRequest extends DiameterMessage {
  AuthenticationInformationRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required String imsi,
    required String visitedPlmnId,
  }) : super.fromFields(
         commandCode: CMD_AUTHENTICATION_INFORMATION,
         applicationId: APP_ID_3GPP_S6A,
         flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
         hopByHopId: DiameterMessage.generateId(),
         endToEndId: DiameterMessage.generateId(),
         avps: [
           AVP.fromString(AVP_SESSION_ID, sessionId),
           AVP.fromUnsigned32(AVP_VENDOR_ID, VENDOR_ID_3GPP),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_3GPP_S6A),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
           AVP.fromString(AVP_USER_NAME, imsi),
           AVP.fromString(
             AVP_VISITED_PLMN_ID,
             visitedPlmnId,
             vendorId: VENDOR_ID_3GPP,
           ),
           AVP.fromGrouped(AVP_REQUESTED_EUTRAN_AUTHENTICATION_INFO, [
             AVP.fromUnsigned32(1409, 1), // Number-Of-Requested-Vectors
             AVP.fromEnumerated(1410, 0), // Immediate-Response-Preferred
           ], vendorId: VENDOR_ID_3GPP),
         ],
       );
}

/// Creates an S6a Authentication-Information-Answer (AIA) message.
class AuthenticationInformationAnswer extends DiameterMessage {
  AuthenticationInformationAnswer.fromRequest(
    DiameterMessage request, {
    required int resultCode,
    required String originHost,
    required String originRealm,
  }) : super.fromFields(
         commandCode: CMD_AUTHENTICATION_INFORMATION,
         applicationId: request.applicationId,
         flags: DiameterMessage.FLAG_PROXYABLE, // Answer
         hopByHopId: request.hopByHopId,
         endToEndId: request.endToEndId,
         avps: [
           request.getAVP(AVP_SESSION_ID)!,
           AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
           AVP.fromUnsigned32(AVP_VENDOR_ID, VENDOR_ID_3GPP),
           AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_3GPP_S6A),
           AVP.fromString(AVP_ORIGIN_HOST, originHost),
           AVP.fromString(AVP_ORIGIN_REALM, originRealm),
           // In a real HSS, this would be populated with actual authentication vectors (RAND, AUTN, XRES, KASME)
           AVP.fromGrouped(
             AVP_AUTHENTICATION_INFO,
             [],
             vendorId: VENDOR_ID_3GPP,
           ),
         ],
       );
}
