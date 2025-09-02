import '../core/diameter_message3.dart';
import '../core/avp_dictionary2.dart';
import 'dart:typed_data';

/// Helper class for the 3GPP Service-Information AVP (Grouped)
class ServiceInformation extends AVP {
  ServiceInformation({
    PsInformation? psInformation,
    // Add other types like ImsInformation, MmsInformation here
  }) : super.fromGrouped(
          AVP_SERVICE_INFORMATION,
          [
            if (psInformation != null) psInformation,
            // Add others to the list
          ],
        ) {
    // Service-Information is a 3GPP specific AVP
    super.flags = super.flags | 0x80; // Set Vendor-Specific flag
    super.vendorId = VENDOR_ID_3GPP;
  }
}

/// Helper class for the 3GPP PS-Information AVP (Grouped)
class PsInformation extends AVP {
  PsInformation({
    required Uint8List chargingId,
    required int pdpType,
    required String pdpAddress,
    // Add other PS-Information fields as needed
  }) : super.fromGrouped(
          AVP_PS_INFORMATION,
          [
            AVP(code: AVP_TGPP_CHARGING_ID, data: chargingId, vendorId: VENDOR_ID_3GPP),
            AVP.fromEnumerated(AVP_TGPP_PDP_TYPE, pdpType)..vendorId = VENDOR_ID_3GPP,
            AVP.fromAddress(AVP_PDP_ADDRESS, pdpAddress)..vendorId = VENDOR_ID_3GPP,
          ],
        ) {
    // PS-Information is a 3GPP specific AVP
    super.flags = super.flags | 0x80; // Set Vendor-Specific flag
    super.vendorId = VENDOR_ID_3GPP;
  }
}

/// Helper class for the Subscription-Id AVP (Grouped)
class SubscriptionId extends AVP {
  SubscriptionId({
    required int subscriptionIdType,
    required String subscriptionIdData,
  }) : super.fromGrouped(
          AVP_SUBSCRIPTION_ID,
          [
            AVP.fromEnumerated(AVP_SUBSCRIPTION_ID_TYPE, subscriptionIdType),
            AVP.fromString(AVP_SUBSCRIPTION_ID_DATA, subscriptionIdData),
          ],
        );
}

/// Helper class for the 3GPP Service-Information AVP (Grouped)
class ServiceInformation extends AVP {
  ServiceInformation({
    PsInformation? psInformation,
    // Add other types like ImsInformation, MmsInformation here
  }) : super.fromGrouped(
          AVP_SERVICE_INFORMATION,
          [
            if (psInformation != null) psInformation,
            // Add others to the list
          ],
        ) {
    // Service-Information is a 3GPP specific AVP
    super.flags = super.flags | 0x80; // Set Vendor-Specific flag
    super.vendorId = VENDOR_ID_3GPP;
  }
}

/// Helper class for the 3GPP PS-Information AVP (Grouped)
class PsInformation extends AVP {
  PsInformation({
    required Uint8List chargingId,
    required int pdpType,
    required String pdpAddress,
    // Add other PS-Information fields as needed
  }) : super.fromGrouped(
          AVP_PS_INFORMATION,
          [
            AVP(code: AVP_TGPP_CHARGING_ID, data: chargingId, vendorId: VENDOR_ID_3GPP),
            AVP.fromEnumerated(AVP_TGPP_PDP_TYPE, pdpType)..vendorId = VENDOR_ID_3GPP,
            AVP.fromAddress(AVP_PDP_ADDRESS, pdpAddress)..vendorId = VENDOR_ID_3GPP,
          ],
        ) {
    // PS-Information is a 3GPP specific AVP
    super.flags = super.flags | 0x80; // Set Vendor-Specific flag
    super.vendorId = VENDOR_ID_3GPP;
  }
}

/// Helper class for the Subscription-Id AVP (Grouped)
class SubscriptionId extends AVP {
  SubscriptionId({
    required int subscriptionIdType,
    required String subscriptionIdData,
  }) : super.fromGrouped(
          AVP_SUBSCRIPTION_ID,
          [
            AVP.fromEnumerated(AVP_SUBSCRIPTION_ID_TYPE, subscriptionIdType),
            AVP.fromString(AVP_SUBSCRIPTION_ID_DATA, subscriptionIdData),
          ],
        );
}


/// Helper class for the 3GPP PS-Information AVP (Grouped)
class PsInformation extends AVP {
  PsInformation({
    required Uint8List chargingId,
    // Add other PS-Information fields as needed
  }) : super(
          code: AVP_PS_INFORMATION,
          vendorId: VENDOR_ID_3GPP,
          flags: AVP.FLAG_VENDOR | AVP.FLAG_MANDATORY,
          avps: [
            AVP(code: AVP_TGPP_CHARGING_ID, vendorId: VENDOR_ID_3GPP, data: chargingId),
            // Add other AVPs here
          ],
        );
}

/// Helper class for the 3GPP IMS-Information AVP (Grouped)
class ImsInformation extends AVP {
  ImsInformation({
    EventType? eventType,
    TimeStamps? timeStamps,
    String? callingPartyAddress,
    // Add other IMS-Information fields as needed
  }) : super(
          code: AVP_IMS_INFORMATION,
          vendorId: VENDOR_ID_3GPP,
          flags: AVP.FLAG_VENDOR | AVP.FLAG_MANDATORY,
          avps: [
            if (eventType != null) eventType,
            if (timeStamps != null) timeStamps,
            if (callingPartyAddress != null)
              AVP.fromString(AVP_CALLING_PARTY_ADDRESS, callingPartyAddress)
                ..vendorId = VENDOR_ID_3GPP,
          ],
        );
}

/// Helper class for the Event-Type AVP (Grouped)
class EventType extends AVP {
  EventType({String? sipMethod, String? event})
      : super.fromGrouped(
          AVP_EVENT_TYPE,
          [
            if (sipMethod != null) AVP.fromString(AVP_SIP_METHOD, sipMethod),
            if (event != null) AVP.fromString(AVP_EVENT, event),
          ],
        ) {
    super.vendorId = VENDOR_ID_3GPP;
  }
}

/// Helper class for the Time-Stamps AVP (Grouped)
class TimeStamps extends AVP {
  TimeStamps({DateTime? sipRequestTimestamp, DateTime? sipResponseTimestamp})
      : super.fromGrouped(
          AVP_TIME_STAMPS,
          [
            if (sipRequestTimestamp != null)
              AVP.fromDateTime(AVP_SIP_REQUEST_TIMESTAMP, sipRequestTimestamp),
            if (sipResponseTimestamp != null)
              AVP.fromDateTime(AVP_SIP_RESPONSE_TIMESTAMP, sipResponseTimestamp),
          ],
        ) {
    super.vendorId = VENDOR_ID_3GPP;
  }
}
