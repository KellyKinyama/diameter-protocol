// lib/applications/session_manager.dart

import 'dart:convert';
import 'dart:typed_data';
import '../core/diameter_message3.dart';
import '../core/avp_dictionary2.dart';
import 'base/capabilities_exchange.dart';
import 'base/disconnect_peer.dart';
// import 'base/watchdog.dart';
import 'base/watchdog2.dart';
import 'session_management.dart';
import 'base/accounting.dart';
import 'credit_control/credit_control4.dart';
import 'nasreq/nasreq.dart';
import 'eap/eap.dart';
import 'sip/sip.dart';

class DiameterSessionManager {
  final Map<String, DiameterSession> sessions = {};
  final String originHost;
  final String originRealm;
  final int _originStateId = DateTime.now().millisecondsSinceEpoch;

  DiameterSessionManager({required this.originHost, required this.originRealm});

  DiameterMessage handleRequest(DiameterMessage request) {
    // Dispatch based on command code
    switch (request.commandCode) {
      // --- Base Protocol Handlers ---
      case CMD_CAPABILITIES_EXCHANGE:
        return _handleCER(request);
      case CMD_DEVICE_WATCHDOG:
        return _handleDWR(request);
      case CMD_DISCONNECT_PEER:
        return _handleDPR(request);

      // --- Base Application Handlers ---
      case CMD_SESSION_TERMINATION:
        return _handleSTR(request);
      case CMD_ACCOUNTING:
        return _handleACR(request);

      // --- Credit-Control Application ---
      case CMD_CREDIT_CONTROL:
        return _handleCCR(request);

      // --- NASREQ Application ---
      case CMD_AA_REQUEST:
        return _handleAAR(request);

      // --- EAP Application ---
      case CMD_DIAMETER_EAP:
        return _handleDER(request);

      // --- SIP Application ---
      case CMD_USER_AUTHORIZATION:
        return _handleUAR(request);
      case CMD_SERVER_ASSIGNMENT:
        return _handleSAR(request);
      case CMD_LOCATION_INFO:
        return _handleLIR(request);
      case CMD_MULTIMEDIA_AUTH:
        return _handleMAR(request);

      // --- Default for unsupported commands ---
      default:
        return createErrorResponse(request, DIAMETER_COMMAND_UNSUPPORTED);
    }
  }

  // --- Handler Implementations ---

  DiameterMessage _handleCER(DiameterMessage cer) {
    print("✅ Handling Capabilities-Exchange-Request (CER)");
    return CapabilitiesExchangeAnswer.fromRequest(
      cer,
      resultCode: DIAMETER_SUCCESS,
      originHost: originHost,
      originRealm: originRealm,
      hostIpAddress: '127.0.0.1',
      vendorId: 10415, // 3GPP
      productName: 'DartDiameterServerV2',
    );
  }

  DiameterMessage _handleDWR(DiameterMessage dwr) {
    print('ℹ️  Received DWR, sending DWA.');
    return DeviceWatchdogAnswer.fromRequest(
      dwr,
      resultCode: DIAMETER_SUCCESS,
      originHost: originHost,
      originRealm: originRealm,
    );
  }

  DiameterMessage _handleDPR(DiameterMessage dpr) {
    print('ℹ️  Received DPR, sending DPA.');
    return DisconnectPeerAnswer.fromRequest(
      dpr,
      resultCode: DIAMETER_SUCCESS,
      originHost: originHost,
      originRealm: originRealm,
    );
  }

  DiameterMessage _handleSTR(DiameterMessage str) {
    final sessionId = utf8.decode(str.getAVP(AVP_SESSION_ID)!.data!);
    if (sessions.containsKey(sessionId)) {
      sessions.remove(sessionId);
      print('✅ Session terminated and removed: $sessionId');
    } else {
      print('⚠️  Received STR for unknown session: $sessionId');
    }
    return SessionTerminationAnswer.fromRequest(
      str,
      resultCode: DIAMETER_SUCCESS,
      originHost: originHost,
      originRealm: originRealm,
    );
  }

  DiameterMessage _handleACR(DiameterMessage acr) {
    final recordType = ByteData.view(
      acr.getAVP(AVP_ACCOUNTING_RECORD_TYPE)!.data!.buffer,
    ).getUint32(0);
    print('🧾 Received ACR (Type: $recordType)');
    // Use the new AccountingAnswer class
    return AccountingAnswer.fromRequest(
      acr,
      resultCode: DIAMETER_SUCCESS,
      originHost: originHost,
      originRealm: originRealm,
    );
  }

  DiameterMessage _handleCCR(DiameterMessage ccr) {
    final sessionId = utf8.decode(ccr.getAVP(AVP_SESSION_ID)!.data!);
    final requestTypeAvp = ccr.getAVP(AVP_CC_REQUEST_TYPE);
    if (requestTypeAvp == null || requestTypeAvp.data == null) {
      return createErrorResponse(ccr, DIAMETER_MISSING_AVP);
    }
    final requestType = ByteData.view(requestTypeAvp.data!.buffer).getUint32(0);

    // Initial Request
    if (requestType == 1) {
      // INITIAL_REQUEST
      if (!sessions.containsKey(sessionId)) {
        sessions[sessionId] = DiameterSession(
          sessionId: sessionId,
          credit: 5000,
        );
        print(
          '💳 New Credit-Control session created: $sessionId with 5000 units',
        );
      }
      final session = sessions[sessionId]!;
      return CreditControlAnswer.fromRequest(
        ccr,
        resultCode: DIAMETER_SUCCESS,
        originHost: originHost,
        originRealm: originRealm,
        grantedUnits: session.credit, // Grant initial units
      );
    }

    // Update Request
    if (requestType == 2) {
      // UPDATE_REQUEST
      final session = sessions[sessionId];
      if (session == null) {
        return createErrorResponse(ccr, DIAMETER_UNKNOWN_SESSION_ID);
      }

      final used = ccr.getAVP(AVP_USED_SERVICE_UNIT);
      if (used != null) {
        // In a real implementation, you'd parse this and deduct from session.credit
        print(
          "💳 CCR-Update: Client reported usage. Session credit remaining: ${session.credit}",
        );
      }

      // Simulate exhausting credit
      session.credit = 0;
      print(
        "🔴 Credit exhausted for session $sessionId. Sending Final-Unit-Indication.",
      );
      return CreditControlAnswer.fromRequest(
        ccr,
        resultCode: DIAMETER_SUCCESS,
        originHost: originHost,
        originRealm: originRealm,
        grantedUnits: 0,
        isFinalUnit: true,
      );
    }

    // Termination Request
    if (requestType == 3) {
      // TERMINATION_REQUEST
      if (sessions.containsKey(sessionId)) {
        sessions.remove(sessionId);
        print('💳 Session terminated and removed: $sessionId');
      }
      return CreditControlAnswer.fromRequest(
        ccr,
        resultCode: DIAMETER_SUCCESS,
        originHost: originHost,
        originRealm: originRealm,
      );
    }

    return createErrorResponse(ccr, DIAMETER_INVALID_AVP_VALUE);
  }

  DiameterMessage _handleAAR(DiameterMessage aar) {
    print("🔧 Handling AA-Request (NASREQ)");
    final userNameAvp = aar.getAVP(AVP_USER_NAME);
    final passwordAvp = aar.getAVP(AVP_USER_PASSWORD);

    if (userNameAvp != null && passwordAvp != null) {
      final username = utf8.decode(userNameAvp.data!);
      final password = utf8.decode(passwordAvp.data!);
      // Simple hardcoded check for demonstration
      if (username == "user@dart.com" && password == "password123") {
        print("✅ NASREQ user authenticated: $username");
        return AAAnswer.fromRequest(
          aar,
          resultCode: DIAMETER_SUCCESS,
          originHost: originHost,
          originRealm: originRealm,
          framedIpAddress: "192.168.1.100", // Assign an IP
        );
      }
    }
    print("❌ NASREQ authentication failed");
    return AAAnswer.fromRequest(
      aar,
      resultCode: DIAMETER_AUTHORIZATION_REJECTED,
      originHost: originHost,
      originRealm: originRealm,
    );
  }

  DiameterMessage _handleDER(DiameterMessage der) {
    print("🔐 Handling Diameter-EAP-Request");
    final sessionId = utf8.decode(der.getAVP(AVP_SESSION_ID)!.data!);
    final session = sessions[sessionId];

    // First round: Server receives EAP-Start or Identity-Response
    if (session == null || session.eapState == 0) {
      sessions[sessionId] = DiameterSession(sessionId: sessionId, eapState: 1);
      print("   -> EAP round 1: Sending challenge");
      return DiameterEAPAnswer.fromRequest(
        der,
        resultCode: DIAMETER_MULTI_ROUND_AUTH,
        originHost: originHost,
        originRealm: originRealm,
        eapPayload: Uint8List.fromList([
          0x01,
          0x02,
          0x00,
          0x08,
          0x04,
          0x01,
          0x02,
          0x03,
        ]), // Dummy EAP Challenge
      );
    }
    // Second round: Server receives challenge response
    else if (session.eapState == 1) {
      session.eapState = 2; // Final state
      print("   -> EAP round 2: Authentication successful");
      // In a real scenario, you would validate the response in EAP-Payload
      return DiameterEAPAnswer.fromRequest(
        der,
        resultCode: DIAMETER_SUCCESS,
        originHost: originHost,
        originRealm: originRealm,
        eapPayload: Uint8List.fromList([0x03, 0x02, 0x00, 0x04]), // EAP-Success
      );
    }
    return createErrorResponse(der, DIAMETER_UNABLE_TO_DELIVER);
  }

  DiameterMessage _handleUAR(DiameterMessage uar) {
    print("📞 Handling User-Authorization-Request (SIP)");
    final sipAor = uar.getAVP(AVP_SIP_AOR);
    if (sipAor != null) {
      print("   -> Authorizing AOR: ${utf8.decode(sipAor.data!)}");
      return UserAuthorizationAnswer.fromRequest(
        uar,
        resultCode: DIAMETER_SUCCESS,
        originHost: originHost,
        originRealm: originRealm,
        sipServerUri: "sip:server.dart.com",
      );
    }
    return createErrorResponse(uar, DIAMETER_MISSING_AVP);
  }

  DiameterMessage _handleSAR(DiameterMessage sar) {
    print("📞 Handling Server-Assignment-Request (SIP)");
    return ServerAssignmentAnswer.fromRequest(
      sar,
      resultCode: DIAMETER_SUCCESS,
      originHost: originHost,
      originRealm: originRealm,
    );
  }

  DiameterMessage _handleLIR(DiameterMessage lir) {
    print("📞 Handling Location-Info-Request (SIP)");
    return LocationInfoAnswer.fromRequest(
      lir,
      resultCode: DIAMETER_SUCCESS,
      originHost: originHost,
      originRealm: originRealm,
      sipServerUri: "sip:located.server.dart.com",
    );
  }

  DiameterMessage _handleMAR(DiameterMessage mar) {
    print("📞 Handling Multimedia-Auth-Request (SIP)");
    return MultimediaAuthAnswer.fromRequest(
      mar,
      resultCode: DIAMETER_SUCCESS,
      originHost: originHost,
      originRealm: originRealm,
    );
  }

  DiameterMessage createErrorResponse(DiameterMessage request, int resultCode) {
    return DiameterMessage.fromFields(
      commandCode: request.commandCode,
      applicationId: request.applicationId,
      flags: DiameterMessage.FLAG_ERROR,
      hopByHopId: request.hopByHopId,
      endToEndId: request.endToEndId,
      avps: [
        AVP.fromUnsigned32(AVP_RESULT_CODE, resultCode),
        AVP.fromString(AVP_ORIGIN_HOST, originHost),
        AVP.fromString(AVP_ORIGIN_REALM, originRealm),
      ],
    );
  }
}

class DiameterSession {
  final String sessionId;
  int credit;
  int eapState; // Simple state for EAP demo
  DiameterSession({
    required this.sessionId,
    this.credit = 0,
    this.eapState = 0,
  });
}
