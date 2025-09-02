// lib/applications/base/capabilities_exchange.dart

import '../../core/avp_dictionary.dart';
import '../../core/diameter_avp.dart';
import '../../core/message_generator.dart';

class CapabilitiesExchangeRequest extends MessageGenerator {
  String originHost;
  String originRealm;
  String hostIpAddress;
  int vendorId;
  String productName;
  int firmwareRevision;
  List<int> authApplicationIds;
  List<int> acctApplicationIds;
  List<int> supportedVendorIds;

  CapabilitiesExchangeRequest({
    required this.originHost,
    required this.originRealm,
    required this.hostIpAddress,
    required this.vendorId,
    required this.productName,
    this.firmwareRevision = 1,
    this.authApplicationIds = const [],
    this.acctApplicationIds = const [],
    this.supportedVendorIds = const [],
  });

  @override
  List<AVP> toAVPs() {
    return [
      AVP.fromValue(AVP_ORIGIN_HOST, originHost),
      AVP.fromValue(AVP_ORIGIN_REALM, originRealm),
      AVP.fromValue(AVP_HOST_IP_ADDRESS, hostIpAddress),
      AVP.fromValue(AVP_VENDOR_ID, vendorId),
      AVP.fromValue(AVP_PRODUCT_NAME, productName),
      AVP.fromValue(AVP_FIRMWARE_REVISION, firmwareRevision),
      ...authApplicationIds.map((id) => AVP.fromValue(AVP_AUTH_APPLICATION_ID, id)),
      ...acctApplicationIds.map((id) => AVP.fromValue(AVP_ACCT_APPLICATION_ID, id)),
      ...supportedVendorIds.map((id) => AVP.fromValue(AVP_SUPPORTED_VENDOR_ID, id)),
    ];
  }
}

class CapabilitiesExchangeAnswer extends MessageGenerator {
  // No specific AVPs needed for the answer besides the standard ones
  @override
  List<AVP> toAVPs() {
    return [];
  }
}