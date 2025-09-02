// test/advanced_credit_control_test.dart

import 'package:test/test.dart';
// import 'package.diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/core/diameter_message4.dart';
import 'package:diameter_protocol/core/message_generator.dart';
import 'package:diameter_protocol/applications/common_3gpp_avps2.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control5.dart';

void main() {
  group('Advanced CreditControlRequest Construction', () {
    test('should generate a complex CCR with nested IMS-Information', () {
      // 1. Define the data for the nested grouped AVPs
      final eventType = EventType(sipMethod: "INVITE", event: "reg");
      final timeStamps = TimeStamps(
        sipRequestTimestamp: DateTime.now(),
        sipResponseTimestamp: DateTime.now(),
      );
      final imsInfo = ImsInformation(
        eventType: eventType,
        timeStamps: timeStamps,
        callingPartyAddress: "41780000000",
      );
      final serviceInfo = ServiceInformation(imsInformation: imsInfo);

      // 2. Create the main CCR generator
      final ccrGenerator = CreditControlRequest.update(
        sessionId:
            "sctp-saegwc-poz01.lte.orange.pl;221424325;287370797;65574b0c-2d02",
        requestNumber: 952,
        serviceContextId: "32251@3gpp.org",
        serviceInformation: serviceInfo,
      );

      // 3. Construct the final Diameter message
      final message = DiameterMessage(
        commandCode: 272,
        applicationId: 4,
        flags: DiameterMessage.FLAG_REQUEST | DiameterMessage.FLAG_PROXYABLE,
        hopByHopId: 1,
        endToEndId: 1,
        generator: ccrGenerator,
      );

      // 4. Verify the structure and perform an encode/decode cycle
      final encoded = message.encode();
      final decoded = DiameterMessage.decode(encoded);

      final decodedServiceInfo = decoded.getAVP(
        AVP_SERVICE_INFORMATION,
        vendorId: VENDOR_ID_3GPP,
      );
      expect(decodedServiceInfo, isNotNull);

      final decodedImsInfo = (decodedServiceInfo!.value as List<AVP>)
          .firstWhere((avp) => avp.code == AVP_IMS_INFORMATION);
      expect(decodedImsInfo, isNotNull);

      final decodedEventType = (decodedImsInfo.value as List<AVP>).firstWhere(
        (avp) => avp.code == AVP_EVENT_TYPE,
      );
      expect(decodedEventType, isNotNull);

      final decodedSipMethod = (decodedEventType.value as List<AVP>).firstWhere(
        (avp) => avp.code == AVP_SIP_METHOD,
      );
      expect(decodedSipMethod.value, "INVITE");
    });
  });
}
