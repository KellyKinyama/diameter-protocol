import 'dart:typed_data';
import '../../core/diameter_message2.dart';
import '../../core/avp_dictionary.dart';
import '../base/capabilities_exchange.dart';

class DiameterSessionManager {
  // ... (properties and other handlers are the same)

  DiameterMessage handleRequest(DiameterMessage request) {
    switch (request.commandCode) {
      // ... (other cases)

      case CMD_AUTHENTICATION_INFORMATION: // New handler for S6a AIR
        return _handleAIR(request);

      // ... (other cases)
    }
    // ...
  }

  /// Handles an incoming AIR and returns an AIA (HSS Function).
  DiameterMessage _handleAIR(DiameterMessage air) {
    final userName = String.fromCharCodes(air.getAVP(AVP_USER_NAME)!.data!);
    print(
      'HSS: Received Authentication Information Request for user (IMSI): $userName',
    );

    // Simulate a 4G/LTE E-UTRAN authentication vector
    final eUtranVector = AVP.fromGrouped(AVP_E_UTRAN_VECTOR, [
      AVP(
        code: AVP_RAND,
        data: Uint8List.fromList(List.generate(16, (i) => i)),
      ), // 16-byte RAND
      AVP(
        code: AVP_XRES,
        data: Uint8List.fromList(List.generate(8, (i) => i)),
      ), // 8-byte XRES
      AVP(
        code: AVP_AUTN,
        data: Uint8List.fromList(List.generate(16, (i) => i)),
      ), // 16-byte AUTN
      AVP(
        code: AVP_KASME,
        data: Uint8List.fromList(List.generate(32, (i) => i)),
      ), // 32-byte KASME
    ]);

    final authInfo = AVP.fromGrouped(AVP_AUTHENTICATION_INFO, [eUtranVector]);

    // Create Authentication-Information-Answer (AIA)
    return DiameterMessage.fromFields(
      commandCode: CMD_AUTHENTICATION_INFORMATION,
      applicationId: air.applicationId,
      flags: 0, // Answer
      hopByHopId: air.hopByHopId,
      endToEndId: air.endToEndId,
      avpList: [
        air.getAVP(AVP_SESSION_ID)!,
        AVP.fromUnsigned32(AVP_RESULT_CODE, DIAMETER_SUCCESS),
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
        AVP.fromUnsigned32(AVP_ORIGIN_STATE_ID, _originStateId),
        authInfo, // Add the authentication vector
      ],
    );
  }

  // ... (rest of the file is unchanged)
}
