
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart' hide SessionRequest;

import '../../../../core/constants/env_config.dart';
import '../../domain/entities/session_request.dart';
import '../../domain/entities/dapp_info.dart';

class WalletConnectService {
  // ignore: deprecated_member_use
  Web3Wallet? _web3Wallet;
  
  // Events
  final StreamController<SessionProposalEvent> _sessionProposalController = StreamController.broadcast();
  final StreamController<SessionRequestEvent> _sessionRequestController = StreamController.broadcast();
  
  Stream<SessionProposalEvent> get onSessionProposal => _sessionProposalController.stream;
  Stream<SessionRequestEvent> get onSessionRequest => _sessionRequestController.stream;

  bool get isInitialized => _web3Wallet != null;

  Future<void> initialize() async {
    if (_web3Wallet != null) return;

    final projectId = EnvConfig.walletConnectProjectId;
    if (projectId.isEmpty) {
      debugPrint('WalletConnect Project ID is missing');
      return;
    }

    try {
      // ignore: deprecated_member_use
      _web3Wallet = await Web3Wallet.createInstance(
        projectId: projectId,
        metadata: const PairingMetadata(
          name: 'Crypto Wallet Pro',
          description: 'A secure Ethereum wallet built with Flutter',
          url: 'https://etherflow.app',
          icons: ['https://cdn-icons-png.flaticon.com/512/2592/2592236.png'], // Placeholder icon
          redirect: Redirect(
            native: 'cryptowalletpro://',
            universal: 'https://etherflow.app',
          ),
        ),
      );

      _web3Wallet!.onSessionProposal.subscribe(_onSessionProposal);
      _web3Wallet!.onSessionRequest.subscribe(_onSessionRequest);
      
      await _web3Wallet!.init();
      debugPrint('WalletConnect initialized');
    } catch (e) {
      debugPrint('Failed to initialize WalletConnect: $e');
    }
  }

  void _onSessionProposal(SessionProposalEvent? event) {
    if (event != null) {
      _sessionProposalController.add(event);
    }
  }

  void _onSessionRequest(SessionRequestEvent? event) {
    if (event != null) {
      _sessionRequestController.add(event);
    }
  }

  Future<void> pair(String uri) async {
    if (_web3Wallet == null) await initialize();
    await _web3Wallet!.pair(uri: Uri.parse(uri));
  }

  Future<void> approveSession({
    required int id,
    required Map<String, Namespace> namespaces,
  }) async {
    if (_web3Wallet == null) return;
    await _web3Wallet!.approveSession(id: id, namespaces: namespaces);
  }

  Future<void> rejectSession({
    required int id,
    required WalletConnectError reason,
  }) async {
    if (_web3Wallet == null) return;
    await _web3Wallet!.rejectSession(id: id, reason: reason);
  }

  Future<void> approveRequest({
    required String topic,
    required int id,
    required String result,
  }) async {
    if (_web3Wallet == null) return;
    await _web3Wallet!.respondSessionRequest(
      topic: topic,
      response: JsonRpcResponse(id: id, result: result),
    );
  }

  Future<void> rejectRequest({
    required String topic,
    required int id,
    required WalletConnectError error,
  }) async {
    if (_web3Wallet == null) return;
    await _web3Wallet!.respondSessionRequest(
      topic: topic,
      response: JsonRpcResponse(id: id, error: JsonRpcError(code: error.code, message: error.message)),
    );
  }


  List<SessionData> getActiveSessions() {
    if (_web3Wallet == null) return [];
    return _web3Wallet!.sessions.getAll();
  }


  List<SessionRequest> getPendingRequests() {
    if (_web3Wallet == null) return [];
    
    final sdkRequests = _web3Wallet!.pendingRequests.getAll();
    return sdkRequests.map((req) {
       // Get session meta for dapp info (if available) - this is tricky as request might not contain full dapp metadata directly, 
       // but we can try to look it up from active sessions or use placeholders.
       // SDK SessionRequest struct usually has topic, which matches a session.
       
       DappInfo dapp = const DappInfo(name: 'Unknown dApp', url: '', iconUrl: '');
       try {
         final session = _web3Wallet!.sessions.get(req.topic);
         if (session != null) {
            dapp = DappInfo(
              name: session.peer.metadata.name,
              url: session.peer.metadata.url,
              iconUrl: session.peer.metadata.icons.isNotEmpty ? session.peer.metadata.icons.first : '',
              description: session.peer.metadata.description,
            );
         }
       } catch (e) {
         // Session might not be found if detached or error
       }

       RequestType type = RequestType.signMessage;
       if (req.method == 'eth_sendTransaction') {
         type = RequestType.sendTransaction;
       } else if (req.method == 'eth_signTypedData' || req.method == 'eth_signTypedData_v4') {
         type = RequestType.signTypedData;
       } else if (req.method == 'personal_sign') {
         type = RequestType.signMessage; // Already default but explicit
       }

       String? chainId = req.chainId;
       // req.params is dynamic. We should try to cast it to Map<String, dynamic> if possible, or wrap it.
       // Usually for these methods, params is a List. We need to convert it to a sensible Map for our Entity.
       Map<String, dynamic> paramsMap = {};
       if (req.params is List) {
         final listParams = req.params as List;
         if (listParams.isNotEmpty) {
           if (type == RequestType.sendTransaction && listParams.first is Map) {
             paramsMap = Map<String, dynamic>.from(listParams.first as Map);
           } else if (type == RequestType.signMessage) {
              // personal_sign: [hexMsg, address]
              if (listParams.isNotEmpty) paramsMap['message'] = listParams[0];
              if (listParams.length >= 2) paramsMap['address'] = listParams[1];
           } else {
             paramsMap['raw'] = listParams;
           }
         }
       } else if (req.params is Map) {
         paramsMap = Map<String, dynamic>.from(req.params as Map);
       }

       return SessionRequest(
         id: req.id.toString(),
         sessionId: req.topic,
         dapp: dapp,
         method: req.method,
         type: type,
         params: paramsMap,
         requestedAt: DateTime.now(), // Request object doesn't have timestamp? SDK might not expose it easily.
         chainId: chainId,
       );
    }).toList();
  }

  Future<void> disconnectSession({required String topic}) async {
    if (_web3Wallet == null) return;
    await _web3Wallet!.disconnectSession(
      topic: topic,
      reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
    );
  }
}
