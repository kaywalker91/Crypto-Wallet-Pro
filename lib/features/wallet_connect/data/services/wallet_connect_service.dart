
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/constants/env_config.dart';

part 'wallet_connect_service.g.dart';

class WalletConnectService {
  late Web3Wallet _web3Wallet;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Web3Wallet get web3Wallet => _web3Wallet;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _web3Wallet = await Web3Wallet.createInstance(
      projectId: EnvConfig.walletConnectProjectId,
      metadata: const PairingMetadata(
        name: 'Crypto Wallet Pro',
        description: 'A secure Ethereum wallet built with Flutter',
        url: 'https://crypto-wallet-pro.com', // Placeholder URL
        icons: ['https://avatars.githubusercontent.com/u/37784886'],
        redirect: Redirect(
          native: 'cryptowalletpro://',
          universal: 'https://crypto-wallet-pro.com',
        ),
      ),
    );

    _isInitialized = true;
  }

  Future<PairingInfo> pair(String uri) async {
    _checkInitialized();
    return await _web3Wallet.pair(uri: Uri.parse(uri));
  }

  Future<ApproveResponse> approveSession({
    required int id,
    required Map<String, Namespace> namespaces,
  }) async {
    _checkInitialized();
    return await _web3Wallet.approveSession(id: id, namespaces: namespaces);
  }

  Future<void> rejectSession({
    required int id,
    required WalletConnectError reason,
  }) async {
    _checkInitialized();
    return await _web3Wallet.rejectSession(id: id, reason: reason);
  }

  Future<void> disconnectSession({
    required String topic,
    required WalletConnectError reason,
  }) async {
    _checkInitialized();
    await _web3Wallet.disconnectSession(topic: topic, reason: reason);
  }

  Future<void> approveRequest({
    required String topic,
    required int requestId,
    required dynamic result,
  }) async {
    _checkInitialized();
    await _web3Wallet.respondSessionRequest(
      topic: topic,
      response: JsonRpcResponse(
        id: requestId,
        result: result,
      ),
    );
  }

  Future<void> rejectRequest({
    required String topic,
    required int requestId,
    required WalletConnectError error,
  }) async {
    _checkInitialized();
    await _web3Wallet.respondSessionRequest(
      topic: topic,
      response: JsonRpcResponse(
        id: requestId,
        error: JsonRpcError(code: error.code, message: error.message),
      ),
    );
  }
  
  // Events
  // Events
  Event<SessionProposalEvent> get sessionProposal => _web3Wallet.onSessionProposal;
  Event<SessionRequestEvent> get sessionRequest => _web3Wallet.onSessionRequest;
  Event<SessionDelete> get sessionDelete => _web3Wallet.onSessionDelete;
  List<SessionData> getActiveSessions() {
     _checkInitialized();
    return _web3Wallet.sessions.getAll();
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('WalletConnectService is not initialized. Call initialize() first.');
    }
  }
}

@Riverpod(keepAlive: true)
WalletConnectService walletConnectService(WalletConnectServiceRef ref) {
  return WalletConnectService();
}
