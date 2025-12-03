import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dapp_info.dart';
import '../../domain/entities/session_request.dart';
import '../../domain/entities/wallet_session.dart';

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

  const WalletConnectState({
    this.sessions = const [],
    this.selectedSession,
    this.pendingRequests = const [],
    this.isLoading = false,
    this.error,
    this.filter = SessionFilter.all,
    this.isScanning = false,
  });

  WalletConnectState copyWith({
    List<WalletSession>? sessions,
    WalletSession? selectedSession,
    List<SessionRequest>? pendingRequests,
    bool? isLoading,
    String? error,
    SessionFilter? filter,
    bool? isScanning,
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
  WalletConnectNotifier() : super(const WalletConnectState(isLoading: true)) {
    _loadMockData();
  }

  /// Load mock data (simulates loading sessions from storage)
  Future<void> _loadMockData() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1200));

      state = WalletConnectState(
        sessions: MockSessions.all,
        pendingRequests: MockRequests.all,
        isLoading: false,
      );
    } catch (e) {
      state = WalletConnectState(
        isLoading: false,
        error: 'Failed to load sessions: $e',
      );
    }
  }

  /// Refresh sessions
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadMockData();
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

  /// Pair with a new dApp (mock implementation)
  Future<void> pair(String uri) async {
    state = state.copyWith(isLoading: true);

    // Simulate pairing delay
    await Future.delayed(const Duration(milliseconds: 800));

    // In real implementation, this would parse the URI and create a session
    // For now, just refresh to simulate the connection
    await _loadMockData();
  }

  /// Approve a pending session
  Future<void> approveSession(String sessionId) async {
    final sessions = state.sessions.map((s) {
      if (s.id == sessionId && s.status == SessionStatus.pending) {
        return WalletSession(
          id: s.id,
          dapp: s.dapp,
          chainId: s.chainId,
          chainName: s.chainName,
          connectedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          status: SessionStatus.active,
          methods: s.methods,
          events: s.events,
          walletAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f5bB12',
        );
      }
      return s;
    }).toList();

    state = state.copyWith(sessions: sessions);
  }

  /// Reject a pending session
  void rejectSession(String sessionId) {
    final sessions = state.sessions.where((s) => s.id != sessionId).toList();
    state = state.copyWith(sessions: sessions);
  }

  /// Disconnect a session
  Future<void> disconnectSession(String sessionId) async {
    state = state.copyWith(isLoading: true);

    // Simulate disconnect delay
    await Future.delayed(const Duration(milliseconds: 500));

    final sessions = state.sessions.where((s) => s.id != sessionId).toList();
    final pendingRequests = state.pendingRequests
        .where((r) => r.sessionId != sessionId)
        .toList();

    state = state.copyWith(
      sessions: sessions,
      pendingRequests: pendingRequests,
      isLoading: false,
      clearSelectedSession: true,
    );
  }

  /// Approve a pending request
  Future<void> approveRequest(String requestId) async {
    state = state.copyWith(isLoading: true);

    // Simulate signing delay
    await Future.delayed(const Duration(milliseconds: 1000));

    final pendingRequests = state.pendingRequests
        .where((r) => r.id != requestId)
        .toList();

    state = state.copyWith(
      pendingRequests: pendingRequests,
      isLoading: false,
    );
  }

  /// Reject a pending request
  void rejectRequest(String requestId) {
    final pendingRequests = state.pendingRequests
        .where((r) => r.id != requestId)
        .toList();

    state = state.copyWith(pendingRequests: pendingRequests);
  }

  /// Get session by ID
  WalletSession? getSessionById(String sessionId) {
    try {
      return state.sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return null;
    }
  }

  /// Get requests for a specific session
  List<SessionRequest> getRequestsForSession(String sessionId) {
    return state.pendingRequests
        .where((r) => r.sessionId == sessionId)
        .toList();
  }
}

/// WalletConnect provider
final walletConnectProvider =
    StateNotifierProvider<WalletConnectNotifier, WalletConnectState>((ref) {
  return WalletConnectNotifier();
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
