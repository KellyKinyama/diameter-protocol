// lib/core/diameter_client.dart

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:diameter_protocol/core/diameter_client.dart';
import 'package:diameter_protocol/core/avp_dictionary.dart';
import 'package:diameter_protocol/applications/base/capabilities_exchange.dart';
import 'package:diameter_protocol/applications/credit_control/credit_control.dart';
import 'package:diameter_protocol/core/diameter_message.dart';

class DiameterClient {
  final String host;
  final int port;
  Socket? _socket;

  // A map to hold pending requests, keyed by their Hop-by-Hop ID.
  final Map<int, Completer<DiameterMessage>> _pendingRequests = HashMap();

  DiameterClient(this.host, this.port);

  Future<void> connect() async {
    try {
      _socket = await Socket.connect(host, port);
      print('✅ Connected to Diameter Server at $host:$port');
      _startListening(); // Start the single, persistent listener.
    } catch (e) {
      print('❌ Failed to connect to Diameter Server: $e');
      rethrow;
    }
  }

  /// Sets up a single listener for the entire life of the socket connection.
  void _startListening() {
    _socket?.listen(
      (data) {
        // This listener handles ALL incoming messages.
        final response = DiameterMessage.decode(data);
        final hopByHopId = response.hopByHopId;

        // Find the completer for this response in our map.
        final completer = _pendingRequests[hopByHopId];

        if (completer != null) {
          // If found, complete the Future with the response.
          completer.complete(response);
          // Remove it from the map as it's no longer pending.
          _pendingRequests.remove(hopByHopId);
        } else {
          print('⚠️ Received response for unknown Hop-by-Hop ID: $hopByHopId');
        }
      },
      onError: (error) {
        print('Socket error: $error');
        // Fail all pending requests if the socket has an error.
        _pendingRequests.forEach((key, completer) {
          completer.completeError(error);
        });
        _pendingRequests.clear();
        _socket?.destroy();
      },
      onDone: () {
        print('🔌 Connection closed by server.');
        // Fail all pending requests if the connection is closed.
        _pendingRequests.forEach((key, completer) {
          completer.completeError(
            'Connection closed before response received.',
          );
        });
        _pendingRequests.clear();
      },
    );
  }

  Future<DiameterMessage> sendRequest(DiameterMessage request) async {
    if (_socket == null) {
      throw StateError('Client not connected. Call connect() first.');
    }

    final completer = Completer<DiameterMessage>();
    final hopByHopId = request.hopByHopId;

    // Add the completer to our map of pending requests.
    _pendingRequests[hopByHopId] = completer;

    print('>> Sending Request:\n$request');
    _socket!.add(request.encode());

    // Return the Future. It will be completed by the central listener.
    return completer.future;
  }

  void disconnect() {
    _socket?.destroy();
    // No need to print here as the onDone handler will cover it.
  }
}

Future<void> main() async {
  final serverHost = '127.0.0.1'; // Replace with your Diameter server's IP
  final serverPort = 3868;

  final client = DiameterClient(serverHost, serverPort);

  try {
    await client.connect();

    // 1. Perform Capabilities Exchange
    final cer = CapabilitiesExchangeRequest(
      originHost: 'client.dart.com',
      originRealm: 'dart.com',
      hostIpAddress: '127.0.0.1',
      vendorId: 10415, // IANA Enterprise Code for 3GPP
      productName: 'DartDiameterV1',
    );
    final cea = await client.sendRequest(cer);
    print('<< Received CEA:\n$cea');

    final resultCode = cea.getAVP(AVP_RESULT_CODE);
    if (resultCode == null ||
        ByteData.view(resultCode.data.buffer).getUint32(0) != 2001) {
      print('CER failed. Aborting.');
      return;
    }

    // 2. Start a new Credit-Control session
    final sessionId =
        'client.dart.com;${DateTime.now().millisecondsSinceEpoch}';
    final ccrInitial = CreditControlRequest.initial(
      sessionId: sessionId,
      originHost: 'client.dart.com',
      originRealm: 'dart.com',
      destinationRealm: 'server.com',
      userName: 'user@dart.com',
    );
    final ccaInitial = await client.sendRequest(ccrInitial);
    print('<< Received CCA (Initial):\n$ccaInitial');

    // ... logic to use the service ...
    await Future.delayed(Duration(seconds: 2));

    // 3. Terminate the Credit-Control session
    final ccrTerminate = CreditControlRequest.terminate(
      sessionId: sessionId,
      originHost: 'client.dart.com',
      originRealm: 'dart.com',
      destinationRealm: 'server.com',
      requestNumber: 1, // The next request number in the session
    );
    final ccaTerminate = await client.sendRequest(ccrTerminate);
    print('<< Received CCA (Terminate):\n$ccaTerminate');
  } catch (e) {
    print('An error occurred: $e');
  } finally {
    client.disconnect();
  }
}
