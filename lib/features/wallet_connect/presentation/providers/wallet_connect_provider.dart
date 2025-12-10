import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart' hide SessionRequest;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../../domain/entities/dapp_info.dart';
import '../../domain/entities/session_request.dart';
import '../../domain/entities/wallet_session.dart';
import '../../data/services/wallet_connect_service.dart';
import '../../../wallet/data/datasources/wallet_local_datasource.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

/// Session filter options
enum SessionFilter {
  all,
  active,
  pending,
}

/// WalletConnect state
class WalletConnectState {
  final List<WalletSession> sessions;
  final WalletSession? selectedSession;
  final List<SessionRequest> pendingRequests;
  final bool isLoading;
  final String? error;
  final SessionFilter filter;
  final bool isScanning;
  
  // Keep track of raw proposals to approve them later
  final Map<String, SessionProposalEvent> proposals;

  const WalletConnectState({
    this.sessions = const [],
    this.selectedSession,
    this.pendingRequests = const [],
    this.isLoading = false,
    this.error,
    this.filter = SessionFilter.all,
    this.isScanning = false,
    this.proposals = const {},
  });

  WalletConnectState copyWith({
    List<WalletSession>? sessions,
    WalletSession? selectedSession,
    List<SessionRequest>? pendingRequests,
    bool? isLoading,
    String? error,
    SessionFilter? filter,
    bool? isScanning,
    Map<String, SessionProposalEvent>? proposals,
    bool clearSelectedSession = false,
    bool clearError = false,
  }) {
    return WalletConnectState(
      sessions: sessions ?? this.sessions,
      selectedSession: clearSelectedSession ? null : (selectedSession ?? this.selectedSession),
      pendingRequests: pendingRequests ?? this.pendingRequests,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
      isScanning: isScanning ?? this.isScanning,
      proposals: proposals ?? this.proposals,
    );
  }

  /// Get filtered sessions based on current filter
  List<WalletSession> get filteredSessions {
    switch (filter) {
      case SessionFilter.all:
        return sessions;
      case SessionFilter.active:
        return sessions.where((s) => s.status == SessionStatus.active).toList();
      case SessionFilter.pending:
        return sessions.where((s) => s.status == SessionStatus.pending).toList();
    }
  }

  /// Total session count
  int get totalCount => sessions.length;

  /// Active session count
  int get activeCount =>
      sessions.where((s) => s.status == SessionStatus.active).length;

  /// Pending session count
  int get pendingCount =>
      sessions.where((s) => s.status == SessionStatus.pending).length;

  /// Expired session count
  int get expiredCount =>
      sessions.where((s) => s.status == SessionStatus.expired).length;

  /// Pending request count
  int get pendingRequestCount => pendingRequests.length;

  /// Check if there are any pending requests
  bool get hasPendingRequests => pendingRequests.isNotEmpty;

  /// Get unique dApps
  List<DappInfo> get connectedDapps {
    return sessions
        .where((s) => s.status == SessionStatus.active)
        .map((s) => s.dapp)
        .toSet()
        .toList();
  }
}

/// WalletConnect state notifier
class WalletConnectNotifier extends StateNotifier<WalletConnectState> {
  final WalletConnectService _service;

  // Event callbacks (dynamic to avoid type issues with EventHandler)
  late dynamic _onSessionProposal;
  late dynamic _onSessionRequest;
  late dynamic _onSessionDelete;

  final WalletLocalDataSource _walletLocalDataSource;

  WalletConnectNotifier(this._service, this._walletLocalDataSource) : super(const WalletConnectState(isLoading: true)) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (!_service.isInitialized) {
        await _service.initialize();
      }
      
      _setupListeners();
      _refreshSessions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to init WalletConnect: $e');
    }
  }

  void _setupListeners() {
    _onSessionProposal = (SessionProposalEvent event) {
      final proposals = Map<String, SessionProposalEvent>.from(state.proposals);
      proposals[event.id.toString()] = event;
      state = state.copyWith(proposals: proposals);
      _rebuildSessionList();
    };

    _onSessionRequest = (SessionRequestEvent event) {
      final request = _mapRequestEventToEntity(event);
      final requests = List<SessionRequest>.from(state.pendingRequests)..add(request);
      state = state.copyWith(pendingRequests: requests);
    };

    _onSessionDelete = (SessionDelete event) {
      _refreshSessions();
    };

    _service.sessionProposal.subscribe(_onSessionProposal);
    _service.sessionRequest.subscribe(_onSessionRequest);
    _service.sessionDelete.subscribe(_onSessionDelete);
  }

  void _refreshSessions() {
    try {
      final activeSessions = _service.getActiveSessions().map(_mapSessionDataToEntity).toList();
      _rebuildSessionList(activeSessions: activeSessions);
    } catch (e) {
      // Handle case where service might not be ready
      print('Error refreshing sessions: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void _rebuildSessionList({List<WalletSession>? activeSessions}) {
     List<WalletSession> active = [];
     if (activeSessions != null) {
       active = activeSessions;
     } else {
       try {
         active = _service.getActiveSessions().map(_mapSessionDataToEntity).toList();
       } catch (_) {}
     }
    
    final pending = state.proposals.values.map((p) {
      return WalletSession(
        id: p.id.toString(),
        dapp: DappInfo(
          name: p.params.proposer.metadata.name,
          url: p.params.proposer.metadata.url,
          iconUrl: p.params.proposer.metadata.icons.isNotEmpty ? p.params.proposer.metadata.icons.first : null,
          description: p.params.proposer.metadata.description,
        ),
        chainId: '', // Can be derived from requiredNamespaces
        chainName: 'Requesting Connection...',
        connectedAt: DateTime.now(),
        status: SessionStatus.pending,
      );
    }).toList();

    state = state.copyWith(
      sessions: [...pending, ...active],
      isLoading: false,
    );
  }

  WalletSession _mapSessionDataToEntity(SessionData data) {
    return WalletSession(
      id: data.topic,
      dapp: DappInfo(
        name: data.peer.metadata.name,
        url: data.peer.metadata.url,
        iconUrl: data.peer.metadata.icons.isNotEmpty ? data.peer.metadata.icons.first : null,
        description: data.peer.metadata.description,
      ),
      chainId: '', // Extract from namespaces if needed
      chainName: 'Connected',
      connectedAt: DateTime.fromMillisecondsSinceEpoch(data.expiry * 1000 - 604800000), // Approx connected time
      expiresAt: DateTime.fromMillisecondsSinceEpoch(data.expiry * 1000),
      status: SessionStatus.active,
      methods: [], // Extract from namespaces
      walletAddress: '', // User's address
    );
  }

  SessionRequest _mapRequestEventToEntity(SessionRequestEvent event) {
    // Find dApp info from session
    final session = state.sessions.firstWhere(
      (s) => s.id == event.topic,
      orElse: () => WalletSession(
        id: event.topic,
        dapp: const DappInfo(name: 'Unknown', url: ''),
        chainId: event.chainId,
        chainName: '',
        connectedAt: DateTime.now(),
        status: SessionStatus.active,
      ),
    );

    return SessionRequest(
      id: event.id.toString(),
      sessionId: event.topic,
      dapp: session.dapp,
      method: event.params.request.method,
      type: _mapMethodToType(event.params.request.method),
      params: event.params.request.params,
      requestedAt: DateTime.now(),
      chainId: event.chainId,
    );
  }

  RequestType _mapMethodToType(String method) {
    if (method.contains('sendTransaction')) return RequestType.sendTransaction;
    if (method.contains('signTransaction')) return RequestType.signTransaction;
    if (method.contains('signTypedData')) return RequestType.signTypedData;
    if (method.contains('personal_sign') || method.contains('eth_sign')) return RequestType.signMessage;
    return RequestType.signMessage;
  }

  @override
  void dispose() {
    _service.sessionProposal.unsubscribe(_onSessionProposal);
    _service.sessionRequest.unsubscribe(_onSessionRequest);
    _service.sessionDelete.unsubscribe(_onSessionDelete);
    super.dispose();
  }

  /// Refresh sessions
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    _refreshSessions();
  }

  /// Select a session for detail view
  void selectSession(WalletSession session) {
    state = state.copyWith(selectedSession: session);
  }

  /// Clear selected session
  void clearSelectedSession() {
    state = state.copyWith(clearSelectedSession: true);
  }

  /// Update filter
  void setFilter(SessionFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// Start QR scanning mode
  void startScanning() {
    state = state.copyWith(isScanning: true);
  }

  /// Stop QR scanning mode
  void stopScanning() {
    state = state.copyWith(isScanning: false);
  }

  /// Pair with a new dApp
  Future<void> pair(String uri) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.pair(uri);
      // Wait for session proposal event to arrive
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Pairing failed: $e');
      rethrow;
    }
  }

  /// Approve a pending session
  Future<void> approveSession(String sessionId) async {
    final proposal = state.proposals[sessionId];
    if (proposal == null) return;

    state = state.copyWith(isLoading: true);
    try {
      // Build namespaces from required and optional
      final namespaces = <String, Namespace>{};
      
      // Get real address
      final privateKey = await _walletLocalDataSource.retrievePrivateKey();
      String userAddress = '';
      if (privateKey != null) {
        final credentials = EthPrivateKey.fromHex(privateKey);
        userAddress = credentials.address.hex;
      } else {
        throw Exception('Wallet not unlocked');
      }

      final chainId = 'eip155:1';

      proposal.params.requiredNamespaces.forEach((key, required) {
         final chains = required.chains ?? [chainId];
         final methods = required.methods;
         final events = required.events;
         
         namespaces[key] = Namespace(
           accounts: chains.map((c) => '$c:$userAddress').toList(),
           methods: methods,
           events: events,
         );
      });
      
      // Also handle optional namespaces if needed, but for now stick to required

      await _service.approveSession(id: proposal.id, namespaces: namespaces);
      
      // Remove from proposals map
      final newProposals = Map<String, SessionProposalEvent>.from(state.proposals);
      newProposals.remove(sessionId);
      state = state.copyWith(proposals: newProposals);
      
      _refreshSessions(); // Will assume session is active now
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to approve session: $e');
    }
  }

  /// Reject a pending session
  Future<void> rejectSession(String sessionId) async {
    final proposal = state.proposals[sessionId];
    if (proposal == null) return;

    try {
      await _service.rejectSession(
        id: proposal.id,
        reason: Errors.getSdkError(Errors.USER_REJECTED),
      );
      
      final newProposals = Map<String, SessionProposalEvent>.from(state.proposals);
      newProposals.remove(sessionId);
      state = state.copyWith(proposals: newProposals);
      _rebuildSessionList();
    } catch (e) {
       state = state.copyWith(error: 'Failed to reject session: $e');
    }
  }

  /// Disconnect a session
  Future<void> disconnectSession(String sessionId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.disconnectSession(
        topic: sessionId,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
      );
    } catch (e) {
       state = state.copyWith(isLoading: false, error: 'Failed to disconnect: $e');
    }
  }

  /// Approve a pending request
  Future<void> approveRequest(String requestId) async {
    final request = state.pendingRequests.firstWhere((r) => r.id == requestId);
    state = state.copyWith(isLoading: true);

    try {
      final privateKey = await _walletLocalDataSource.retrievePrivateKey();
      if (privateKey == null) {
        throw Exception('Wallet not found or locked');
      }

      final credentials = EthPrivateKey.fromHex(privateKey);
      String result;

      if (request.method == 'personal_sign' || request.method == 'eth_sign') {
        // params: [message, address]
        final List params = request.params is List ? request.params as List : [];
        if (params.isEmpty) throw Exception('Invalid parameters');
        
        final message = params.first as String;
        Uint8List messageBytes;
        if (message.startsWith('0x')) {
           messageBytes = hexToBytes(message);
        } else {
           messageBytes = Uint8List.fromList(utf8.encode(message));
        }
        
        final signature = await credentials.signPersonalMessage(messageBytes);
        result = bytesToHex(signature, include0x: true);
        
      } else if (request.method == 'eth_sendTransaction') {
        final List listParams = request.params is List ? request.params as List : [];
        if (listParams.isEmpty) throw Exception('Invalid parameters');
        
        // This is a placeholder. Real implementation needs Web3Client.
        throw Exception('Send transaction via WalletConnect is currently not supported. Please use the Send feature in the app.');
      } else if (request.method == 'eth_signTransaction') {
         // Should sign and return raw transaction
         throw Exception('Sign transaction not implemented.');
      } else if (request.method.startsWith('eth_signTypedData')) {
        // Handle typed data
         throw Exception('Sign typed data not implemented.');
      } else {
        throw Exception('Unsupported method: ${request.method}');
      }

      await _service.approveRequest(
         topic: request.sessionId,
         requestId: int.parse(request.id),
         result: result,
      );
      
      final pendingRequests = state.pendingRequests.where((r) => r.id != requestId).toList();
      state = state.copyWith(pendingRequests: pendingRequests);
      
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Request failed: $e');
    }
  }

  /// Reject a pending request
  Future<void> rejectRequest(String requestId) async {
    final request = state.pendingRequests.firstWhere((r) => r.id == requestId);
    
    await _service.rejectRequest(
      topic: request.sessionId,
      requestId: int.parse(request.id),
      error: Errors.getSdkError(Errors.USER_REJECTED),
    );
    
    final pendingRequests = state.pendingRequests.where((r) => r.id != requestId).toList();
    state = state.copyWith(pendingRequests: pendingRequests);
  }
  
  // Getters for providers
  WalletSession? getSessionById(String sessionId) {
    try {
      return state.sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return null;
    }
  }

  List<SessionRequest> getRequestsForSession(String sessionId) {
    return state.pendingRequests
        .where((r) => r.sessionId == sessionId)
        .toList();
  }
}

/// WalletConnect provider
final walletConnectProvider =
    StateNotifierProvider<WalletConnectNotifier, WalletConnectState>((ref) {
  final service = ref.watch(walletConnectServiceProvider);
  final walletLocalDataSource = ref.watch(walletLocalDataSourceProvider);
  return WalletConnectNotifier(service, walletLocalDataSource);
});

/// Selected session provider
final selectedSessionProvider = Provider<WalletSession?>((ref) {
  return ref.watch(walletConnectProvider).selectedSession;
});

/// Session filter provider
final sessionFilterProvider = Provider<SessionFilter>((ref) {
  return ref.watch(walletConnectProvider).filter;
});

/// Filtered sessions provider
final filteredSessionsProvider = Provider<List<WalletSession>>((ref) {
  return ref.watch(walletConnectProvider).filteredSessions;
});

/// Session loading state provider
final sessionLoadingProvider = Provider<bool>((ref) {
  return ref.watch(walletConnectProvider).isLoading;
});

/// Session error state provider
final sessionErrorProvider = Provider<String?>((ref) {
  return ref.watch(walletConnectProvider).error;
});

/// Session count providers
final sessionCountProvider = Provider<({int total, int active, int pending})>((ref) {
  final state = ref.watch(walletConnectProvider);
  return (
    total: state.totalCount,
    active: state.activeCount,
    pending: state.pendingCount,
  );
});

/// Pending requests provider
final pendingRequestsProvider = Provider<List<SessionRequest>>((ref) {
  return ref.watch(walletConnectProvider).pendingRequests;
});

/// Has pending requests provider
final hasPendingRequestsProvider = Provider<bool>((ref) {
  return ref.watch(walletConnectProvider).hasPendingRequests;
});

/// Connected dApps provider
final connectedDappsProvider = Provider<List<DappInfo>>((ref) {
  return ref.watch(walletConnectProvider).connectedDapps;
});

/// Scanning state provider
final isScanningProvider = Provider<bool>((ref) {
  return ref.watch(walletConnectProvider).isScanning;
});
