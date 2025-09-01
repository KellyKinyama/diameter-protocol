import 'dart:typed_data';
import '../../core/diameter_message.dart';
import '../../core/avp_dictionary.dart';

/// Creates an S6a Update-Location-Request (ULR) message.
class UpdateLocationRequest extends DiameterMessage {
  // ... (existing ULR class is unchanged)
}

/// Creates an S6a Authentication-Information-Request (AIR) message.
/// This is sent by an MME to the HSS to fetch authentication vectors.
class AuthenticationInformationRequest extends DiameterMessage {
  AuthenticationInformationRequest({
    required String sessionId,
    required String originHost,
    required String originRealm,
    required String destinationRealm,
    required String userName, // This carries the IMSI
    required List<int> visitedPlmnId,
  }) : super(
          length: 20 +
              [
                AVP.fromString(AVP_SESSION_ID, sessionId),
                AVP.fromString(AVP_ORIGIN_HOST, originHost),
                AVP.fromString(AVP_ORIGIN_REALM, originRealm),
                AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
                AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_S6A),
                AVP.fromString(AVP_USER_NAME, userName),
                AVP(code: AVP_VISITED_PLMN_ID, data: Uint8List.fromList(visitedPlmnId)),
              ].fold(0, (sum, avp) => sum + avp.getPaddedLength()),
          commandCode: CMD_AUTHENTICATION_INFORMATION,
          applicationId: APP_ID_S6A,
          flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
          hopByHopId: DiameterMessage.generateId(),
          endToEndId: DiameterMessage.generateId(),
          version: 1,
          avps: [
            AVP.fromString(AVP_SESSION_ID, sessionId),
            AVP.fromString(AVP_ORIGIN_HOST, originHost),
            AVP.fromString(AVP_ORIGIN_REALM, originRealm),
            AVP.fromString(AVP_DESTINATION_REALM, destinationRealm),
            AVP.fromUnsigned32(AVP_AUTH_APPLICATION_ID, APP_ID_S6A),
            AVP.fromString(AVP_USER_NAME, userName),
            AVP(code: AVP_VISITED_PLMN_ID, data: Uint8List.fromList(visitedPlmnId)),
          ],
        );
}
