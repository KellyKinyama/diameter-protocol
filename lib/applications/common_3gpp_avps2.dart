// lib/applications/common_3gpp_avps.dart

import 'package:diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/core/diameter_avp.dart';
import 'package:diameter_protocol/core/message_generator.dart';

// --- Generators for nested 3GPP Grouped AVPs ---

class EventType extends MessageGenerator {
  String? sipMethod;
  String? event;

  EventType({this.sipMethod, this.event});

  @override
  List<AVP> toAVPs() {
    final avps = <AVP>[];
    if (sipMethod != null) {
      avps.add(AVP.fromValue(AVP_SIP_METHOD, sipMethod!, vendorId: VENDOR_ID_3GPP));
    }
    if (event != null) {
      avps.add(AVP.fromValue(AVP_EVENT, event!, vendorId: VENDOR_ID_3GPP));
    }
    return avps;
  }
}

class TimeStamps extends MessageGenerator {
  DateTime? sipRequestTimestamp;
  DateTime? sipResponseTimestamp;

  TimeStamps({this.sipRequestTimestamp, this.sipResponseTimestamp});

  @override
  List<AVP> toAVPs() {
    final avps = <AVP>[];
    if (sipRequestTimestamp != null) {
      avps.add(AVP.fromValue(AVP_SIP_REQUEST_TIMESTAMP, sipRequestTimestamp!.millisecondsSinceEpoch ~/ 1000, vendorId: VENDOR_ID_3GPP));
    }
    if (sipResponseTimestamp != null) {
      avps.add(AVP.fromValue(AVP_SIP_RESPONSE_TIMESTAMP, sipResponseTimestamp!.millisecondsSinceEpoch ~/ 1000, vendorId: VENDOR_ID_3GPP));
    }
    return avps;
  }
}

class ImsInformation extends MessageGenerator {
  EventType? eventType;
  TimeStamps? timeStamps;
  String? callingPartyAddress;

  ImsInformation({this.eventType, this.timeStamps, this.callingPartyAddress});

  @override
  List<AVP> toAVPs() {
    final avps = <AVP>[];
    if (eventType != null) {
      avps.add(AVP.fromValue(AVP_EVENT_TYPE, eventType!.toAVPs(), vendorId: VENDOR_ID_3GPP));
    }
    if (timeStamps != null) {
      avps.add(AVP.fromValue(AVP_TIME_STAMPS, timeStamps!.toAVPs(), vendorId: VENDOR_ID_3GPP));
    }
    if (callingPartyAddress != null) {
      avps.add(AVP.fromValue(AVP_CALLING_PARTY_ADDRESS, callingPartyAddress!, vendorId: VENDOR_ID_3GPP));
    }
    return avps;
  }
}

class ServiceInformation extends MessageGenerator {
  ImsInformation? imsInformation;
  // Other service information types (PS, MMS, etc.) would be added here
  
  ServiceInformation({this.imsInformation});

  @override
  List<AVP> toAVPs() {
    final avps = <AVP>[];
    if (imsInformation != null) {
      avps.add(AVP.fromValue(AVP_IMS_INFORMATION, imsInformation!.toAVPs(), vendorId: VENDOR_ID_3GPP));
    }
    return avps;
  }
}