

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart' hide SessionRequest;
import '../../data/services/wallet_connect_service.dart';
import '../../domain/entities/wallet_session.dart';
import '../../domain/entities/dapp_info.dart';


import '../../domain/entities/session_request.dart';

part 'wallet_connect_provider.g.dart';

enum SessionFilter { all, active, pending }

class WalletConnectState {
  final List<WalletSession> sessions;
  final bool isLoading;
  final String? error;
  final SessionFilter filter;
  final List<SessionRequest> pendingRequests;

  const WalletConnectState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.filter = SessionFilter.all,
    this.pendingRequests = const [],
  });

  bool get hasPendingRequests => pendingRequests.isNotEmpty;
  int get pendingRequestCount => pendingRequests.length;

  List<WalletSession> get filteredSessions {
    switch (filter) {
      case SessionFilter.all:
        return sessions;
      case SessionFilter.active:
        return sessions.where((s) => s.isActive).toList();
      case SessionFilter.pending:
        return [];
    }
  }

  WalletConnectState copyWith({
    List<WalletSession>? sessions,
    bool? isLoading,
    String? error,
    SessionFilter? filter,
    List<SessionRequest>? pendingRequests,
  }) {
    return WalletConnectState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
      pendingRequests: pendingRequests ?? this.pendingRequests,
    );
  }
}

@Riverpod(keepAlive: true)
WalletConnectService walletConnectService(Ref ref) {
  final service = WalletConnectService();
  service.initialize();
  return service;
}

@Riverpod(keepAlive: true)
class WalletConnectNotifier extends _$WalletConnectNotifier {
  late final WalletConnectService _service;

  @override
  WalletConnectState build() {
    _service = ref.watch(walletConnectServiceProvider);
    
    _service.onSessionRequest.listen((_) => refresh());
    _service.onSessionProposal.listen((_) => refresh());

    // Schedule initial data load
    Future.microtask(() => _loadData());
    
    return const WalletConnectState(isLoading: true);
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final sessionsData = _service.getActiveSessions();
      final requests = _service.getPendingRequests();
      

      final sessions = sessionsData.map((s) {
        String chainId = '';
        String walletAddress = '';
        if (s.namespaces.isNotEmpty) {
           final namespace = s.namespaces.values.first;
           if (namespace.accounts.isNotEmpty) {
             final accountParts = namespace.accounts.first.split(':');
             if (accountParts.length >= 3) {
               chainId = '${accountParts[0]}:${accountParts[1]}';
               walletAddress = accountParts[2];
             }
           }
        }

        return WalletSession(
          id: s.topic,
          dapp: DappInfo(
            name: s.peer.metadata.name,
            url: s.peer.metadata.url,
            iconUrl: s.peer.metadata.icons.isNotEmpty ? s.peer.metadata.icons.first : '',
            description: s.peer.metadata.description,
          ),
          chainId: chainId,
          chainName: 'Ethereum', // Simplified for now
          connectedAt: DateTime.now(), // Approximate as we don't have start time in SessionData easily
          expiresAt: DateTime.fromMillisecondsSinceEpoch(s.expiry * 1000),
          status: SessionStatus.active,
          walletAddress: walletAddress,
        );
      }).toList();

      state = state.copyWith(
        isLoading: false,
        sessions: sessions,
        pendingRequests: requests,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await _loadData();
  }

  void setFilter(SessionFilter filter) {
    state = state.copyWith(filter: filter);
  }


  Future<void> disconnectSession(String topic) async {
    try {
      await _service.disconnectSession(topic: topic);
      refresh();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  Future<void> approveSession(String proposalIdRaw) async {
      // The session ID in the service is likely an int, but the entity generally uses String for UI.
      // Need to parse if strictly int, or if service accepts string.
      // Checking Service (Step 285): approveSession takes int id.
      // Checking WalletSession (Step 294): id is String.
      // WalletConnect v2 session IDs (topics) are strings, but Proposal IDs are integers.
      // The WalletSession entity seems to handle both active (String topic) and pending (Int proposal ID converted to String?).
      
      try {
        final id = int.tryParse(proposalIdRaw);
        if (id != null) {
            // We need to implement default namespaces here or pass them in.
            // For now, let's assume a default implementation or user-provided one.
             final namespaces = {
              'eip155': Namespace(
                accounts: ['eip155:1:0x000'], // Placeholder, needs actual logic
                methods: ['eth_sendTransaction', 'personal_sign', 'eth_signTypedData'],
                events: ['chainChanged', 'accountsChanged'],
              ),
            };
           await _service.approveSession(id: id, namespaces: namespaces);
           refresh();
        }
      } catch (e) {
           debugPrint('Error approving session: $e');
      }
  }
    
  Future<void> rejectSession(String proposalIdRaw) async {
    try {
       final id = int.tryParse(proposalIdRaw);
       if (id != null) {
         await _service.rejectSession(
           id: id,
           reason: Errors.getSdkError(Errors.USER_REJECTED),
         );
         refresh();
       }
    } catch (e) {
       debugPrint('Error rejecting session: $e');
    }
  }

  Future<void> approveRequest(String idRaw) async {
    final id = int.tryParse(idRaw);
    if (id == null) return;
    // This calls back to service
    // Implementation depends on request type
    // Placeholder
  }

  Future<void> rejectRequest(String idRaw) async {
    final id = int.tryParse(idRaw);
    if (id == null) return;
    // Placeholder
  }

  void selectSession(WalletSession session) {
    // Handle session selection if needed
  }
}

// Alias for easy access
final walletConnectProvider =
    NotifierProvider<WalletConnectNotifier, WalletConnectState>(
        WalletConnectNotifier.new);

final sessionFilterProvider = Provider<SessionFilter>((ref) {
  return ref.watch(walletConnectProvider).filter;
});

final pendingRequestsProvider = Provider<List<SessionRequest>>((ref) {
  return ref.watch(walletConnectProvider).pendingRequests;
});

final sessionCountProvider = Provider<({int total, int active, int pending})>((ref) {
  final state = ref.watch(walletConnectProvider);
  return (
    total: state.sessions.length,
    active: state.sessions.where((s) => s.isActive).length,
    pending: state.pendingRequests.length,
  );
});
