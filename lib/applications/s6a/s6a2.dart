// lib/applications/s6a/s6a.dart

import 'dart:convert';
import 'dart:typed_data';
import '../../core/avp_dictionary.dart';
import '../../core/diameter_avp.dart';
import '../../core/message_generator.dart';
import 'hss_service.dart';

/// Generator for an S6a Update-Location-Request (ULR) message.
class UpdateLocationRequest extends MessageGenerator {
  String sessionId;
  String userName; // IMSI
  String visitedPlmnId;
  int ulrFlags;
  int ratType;

  UpdateLocationRequest({
    required this.sessionId,
    required this.userName,
    required this.visitedPlmnId,
    this.ulrFlags = 1, // Single-Registration-Indication
    this.ratType = 1004, // EUTRAN
  });

  @override
  List<AVP> toAVPs() {
    return [
      AVP.fromValue(AVP_SESSION_ID, sessionId),
      AVP.fromValue(AVP_USER_NAME, userName),
      AVP.fromValue(1407, utf8.encode(visitedPlmnId), vendorId: 10415), // Visited-PLMN-Id
      AVP.fromValue(1405, ulrFlags, vendorId: 10415), // ULR-Flags
      AVP.fromValue(1032, ratType, vendorId: 10415), // RAT-Type
    ];
  }
}

/// Generator for an S6a Update-Location-Answer (ULA) message.
class UpdateLocationAnswer extends MessageGenerator {
  SubscriptionData? subscriptionData;

  UpdateLocationAnswer({this.subscriptionData});

  @override
  List<AVP> toAVPs() {
    final avps = <AVP>[];
    if (subscriptionData != null) {
      avps.add(AVP.fromValue(
        1400, // Subscription-Data
        [
          // In a real HSS, you would map all profile fields to AVPs here.
          AVP.fromValue(1424, subscriptionData!.accessRestrictionData, vendorId: 10415), // Access-Restriction-Data
        ],
        vendorId: 10415,
      ));
    }
    return avps;
  }
}

/// Generator for an S6a Authentication-Information-Request (AIR) message.
class AuthenticationInformationRequest extends MessageGenerator {
  String sessionId;
  String userName; // IMSI
  String visitedPlmnId;

  AuthenticationInformationRequest({
    required this.sessionId,
    required this.userName,
    required this.visitedPlmnId,
  });

  @override
  List<AVP> toAVPs() {
    return [
      AVP.fromValue(AVP_SESSION_ID, sessionId),
      AVP.fromValue(AVP_USER_NAME, userName),
      AVP.fromValue(1407, utf8.encode(visitedPlmnId), vendorId: 10415), // Visited-PLMN-Id
      AVP.fromValue(
        1408, // Requested-EUTRAN-Authentication-Info
        [
          AVP.fromValue(1409, 1, vendorId: 10415), // Number-Of-Requested-Vectors
          AVP.fromValue(1410, 0, vendorId: 10415), // Immediate-Response-Preferred
        ],
        vendorId: 10415,
      ),
    ];
  }
}

/// Generator for an S6a Authentication-Information-Answer (AIA) message.
class AuthenticationInformationAnswer extends MessageGenerator {
  AuthenticationVector? authVector;

  AuthenticationInformationAnswer({this.authVector});

  @override
  List<AVP> toAVPs() {
    final avps = <AVP>[];
    if (authVector != null) {
      avps.add(AVP.fromValue(
        1413, // Authentication-Info
        [
          AVP.fromValue(
            1414, // E-UTRAN-Vector
            [
              AVP.fromValue(1415, authVector!.rand as Uint8List, vendorId: 10415),  // RAND
              AVP.fromValue(1416, authVector!.xres as Uint8List, vendorId: 10415),  // XRES
              AVP.fromValue(1417, authVector!.autn as Uint8List, vendorId: 10415),  // AUTN
              AVP.fromValue(1418, authVector!.kasme as Uint8List, vendorId: 10415), // KASME
            ],
            vendorId: 10415,
          )
        ],
        vendorId: 10415,
      ));
    }
    return avps;
  }
}