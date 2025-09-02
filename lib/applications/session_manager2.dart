// lib/applications/session_manager.dart

import 'dart:convert';
import 'dart:typed_data';
import '../core/diameter_message4.dart';
import '../core/avp_dictionary.dart';
import '../core/diameter_avp.dart';
import '../core/message_generator.dart';
import 'base/capabilities_exchange2.dart';
import 'base/disconnect_peer2.dart';
import 'base/watchdog3.dart';
import 'base/session_management.dart';
import 'base/accounting2.dart';
import 'credit_control/credit_control5.dart';
import 's6a/hss_service.dart';
// import 's6a/s6a.dart';
import 's6a/s6a2.dart';

class DiameterSessionManager {
  final String originHost;
  final String originRealm;
  final HssService hssService;
  final Map<String, dynamic> sessions = {};

  DiameterSessionManager({
    required this.originHost,
    required this.originRealm,
    required this.hssService,
  });

  /// Main dispatcher. It is now async to handle async service calls.
  Future<DiameterMessage> handleRequest(DiameterMessage request) async {
    MessageGenerator responseGenerator;
    int resultCode = 2001; // DIAMETER_SUCCESS

    try {
      switch (request.commandCode) {
        case 316: // Update-Location
          responseGenerator = await _handleULR(request);
          break;
        case 318: // Authentication-Information
          responseGenerator = await _handleAIR(request);
          break;
        case 272: // Credit-Control
          responseGenerator = _handleCCR(request);
          break;
        case 257: // Capabilities-Exchange
          responseGenerator = _handleCER(request);
          break;
        case 280: // Device-Watchdog
          responseGenerator = _handleDWR(request);
          break;
        case 282: // Disconnect-Peer
          responseGenerator = _handleDPR(request);
          break;
        case 275: // Session-Termination
          responseGenerator = _handleSTR(request);
          break;
        case 271: // Accounting
          responseGenerator = _handleACR(request);
          break;
        default:
          resultCode = 3001; // DIAMETER_COMMAND_UNSUPPORTED
          responseGenerator = GenericAnswer();
      }
    } catch (e) {
      print("❌ Error processing request: $e");
      resultCode = 5012; // DIAMETER_UNABLE_TO_COMPLY
      responseGenerator = GenericAnswer();
    }

    // Add common AVPs to the response generator's list
    final responseAvps = responseGenerator.toAVPs();
    responseAvps.insert(0, AVP.fromValue(AVP_RESULT_CODE, resultCode));
    responseAvps.insert(1, AVP.fromValue(AVP_ORIGIN_HOST, originHost));
    responseAvps.insert(2, AVP.fromValue(AVP_ORIGIN_REALM, originRealm));

    // Create the final DiameterMessage from the generator
    return DiameterMessage(
      commandCode: request.commandCode,
      applicationId: request.applicationId,
      flags: 0, // Answer
      hopByHopId: request.hopByHopId,
      endToEndId: request.endToEndId,
      generator: RawAVPGenerator(responseAvps),
    );
  }

  Future<MessageGenerator> _handleULR(DiameterMessage ulr) async {
    final imsi = ulr.getAVP(1)!.value as String; // User-Name
    final visitedPlmnIdBytes =
        ulr.getAVP(1407, vendorId: 10415)!.value as Uint8List;
    final visitedPlmnId = utf8.decode(visitedPlmnIdBytes);

    final subscriptionData = await hssService.handleUpdateLocation(
      imsi,
      visitedPlmnId,
    );

    if (subscriptionData == null) {
      throw Exception("User not found");
    }

    return UpdateLocationAnswer(subscriptionData: subscriptionData);
  }

  Future<MessageGenerator> _handleAIR(DiameterMessage air) async {
    final imsi = air.getAVP(1)!.value as String;
    final authVector = await hssService.handleAuthenticationInformation(imsi);
    if (authVector == null) {
      throw Exception("User not found");
    }
    return AuthenticationInformationAnswer(authVector: authVector);
  }

  MessageGenerator _handleCCR(DiameterMessage ccr) {
    final sessionId = ccr.getAVP(AVP_SESSION_ID)!.value as String;
    final requestType = ccr.getAVP(AVP_CC_REQUEST_TYPE)!.value as int;
    final requestNumber = ccr.getAVP(AVP_CC_REQUEST_NUMBER)!.value as int;

    // Simple Gy logic
    if (requestType == 1) {
      // INITIAL
      sessions[sessionId] = {'credit': 5000};
      return CreditControlAnswer(
        sessionId: sessionId,
        requestType: requestType,
        requestNumber: requestNumber,
        grantedUnits: 5000,
      );
    }
    if (requestType == 2) {
      // UPDATE
      sessions[sessionId]['credit'] = 0;
      return CreditControlAnswer(
        sessionId: sessionId,
        requestType: requestType,
        requestNumber: requestNumber,
        grantedUnits: 0,
        isFinalUnit: true,
      );
    }
    if (requestType == 3) {
      // TERMINATION
      sessions.remove(sessionId);
      return CreditControlAnswer(
        sessionId: sessionId,
        requestType: requestType,
        requestNumber: requestNumber,
      );
    }
    throw Exception("Unknown CC-Request-Type");
  }

  MessageGenerator _handleCER(DiameterMessage cer) {
    return CapabilitiesExchangeAnswer(
      // originHost: '127.0.0.1',
      // vendorId: 10415,
      // productName: 'DartDiameterServerV2',
      // authApplicationIds: [16777251], // S6a
      // supportedVendorIds: [10415],
    );
  }

  MessageGenerator _handleDWR(DiameterMessage dwr) {
    return DeviceWatchdogAnswer();
  }

  MessageGenerator _handleDPR(DiameterMessage dpr) {
    return DisconnectPeerAnswer();
  }

  MessageGenerator _handleSTR(DiameterMessage str) {
    final sessionId = str.getAVP(AVP_SESSION_ID)!.value as String;
    sessions.remove(sessionId);
    return SessionTerminationAnswer(sessionId: sessionId);
  }

  MessageGenerator _handleACR(DiameterMessage acr) {
    final sessionId = acr.getAVP(AVP_SESSION_ID)!.value as String;
    final recordType = acr.getAVP(AVP_ACCOUNTING_RECORD_TYPE)!.value as int;
    final recordNumber = acr.getAVP(AVP_ACCOUNTING_RECORD_NUMBER)!.value as int;
    return AccountingAnswer(
      sessionId: sessionId,
      accountingRecordType: recordType,
      accountingRecordNumber: recordNumber,
    );
  }
}

/// A generic generator for creating simple answers or error responses.
class GenericAnswer extends MessageGenerator {
  @override
  List<AVP> toAVPs() => [];
}

/// A generator that just wraps a pre-built list of AVPs.
class RawAVPGenerator extends MessageGenerator {
  final List<AVP> avps;
  RawAVPGenerator(this.avps);
  @override
  List<AVP> toAVPs() => avps;
}
