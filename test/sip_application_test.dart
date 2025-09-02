// test/sip_application_test.dart

import 'package:test/test.dart';
import 'package:diameter_protocol/applications/sip/sip2.dart';
import 'package:diameter_protocol/core/diameter_message4.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';

void main() {
  group('SIP Application Messages', () {
    test('UserAuthorizationRequest should be constructed correctly', () {
      final uarGenerator = UserAuthorizationRequest(
        sessionId: 'sip-session;1',
        userName: 'sip:user@example.com',
        sipAuthDataItem: SipAuthDataItem(sipAuthenticationScheme: "Unknown"),
      );

      final message = DiameterMessage(
        commandCode: 283, // User-Authorization
        applicationId: 6, // SIP
        flags: DiameterMessage.FLAG_REQUEST,
        hopByHopId: 1,
        endToEndId: 1,
        generator: uarGenerator,
      );

      expect(message.getAVP(AVP_USER_NAME)?.value, 'sip:user@example.com');
      final authItem = message.getAVP(
        376,
        vendorId: 10415,
      ); // SIP-Auth-Data-Item
      expect(authItem, isNotNull);
      expect(authItem!.value, isA<List>());
    });

    test('ServerAssignmentRequest should be constructed correctly', () {
      final sarGenerator = ServerAssignmentRequest(
        sessionId: 'sip-session;2',
        userName: 'sip:user@example.com',
        serverAssignmentType: 1, // REGISTRATION
      );

      final message = DiameterMessage(
        commandCode: 284, // Server-Assignment
        applicationId: 6,
        flags: DiameterMessage.FLAG_REQUEST,
        hopByHopId: 1,
        endToEndId: 1,
        generator: sarGenerator,
      );

      expect(
        message.getAVP(370, vendorId: 10415)?.value,
        1,
      ); // Server-Assignment-Type
    });
  });
}
