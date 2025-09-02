// test/accounting_test.dart

import 'package:test/test.dart';
import 'package:diameter_protocol/applications/base/accounting2.dart';
import 'package:diameter_protocol/core/diameter_message4.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';

void main() {
  group('AccountingRequest', () {
    test('should generate a valid ACR-Start', () {
      final acrGenerator = AccountingRequest(
        sessionId: 'test-acct-session;1',
        accountingRecordType: 2, // START_RECORD
        accountingRecordNumber: 0,
        // originHost: 'nas.test.com',
        // originRealm: 'test.com',
        // destinationRealm: 'accounting.test.com'
      );

      final message = DiameterMessage(
        commandCode: 271,
        applicationId: 3,
        flags: DiameterMessage.FLAG_REQUEST,
        hopByHopId: 1,
        endToEndId: 1,
        generator: acrGenerator,
      );

      expect(message.getAVP(AVP_SESSION_ID)?.value, 'test-acct-session;1');
      expect(message.getAVP(AVP_ACCOUNTING_RECORD_TYPE)?.value, 2);
      expect(message.getAVP(AVP_ACCOUNTING_RECORD_NUMBER)?.value, 0);

      final encoded = message.encode();
      final decoded = DiameterMessage.decode(encoded);

      expect(decoded.commandCode, message.commandCode);
      expect(decoded.getAVP(AVP_SESSION_ID)?.value, 'test-acct-session;1');
    });
  });
}
