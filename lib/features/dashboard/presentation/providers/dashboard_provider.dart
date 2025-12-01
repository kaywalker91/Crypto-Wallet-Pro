import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/token.dart';
import '../../domain/entities/wallet_balance.dart';

/// Dashboard state
class DashboardState {
  final WalletBalance? walletBalance;
  final List<Token> tokens;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.walletBalance,
    this.tokens = const [],
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    WalletBalance? walletBalance,
    List<Token>? tokens,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      walletBalance: walletBalance ?? this.walletBalance,
      tokens: tokens ?? this.tokens,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Dashboard notifier for managing state
class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(const DashboardState(isLoading: true)) {
    _loadMockData();
  }

  Future<void> _loadMockData() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    state = DashboardState(
      walletBalance: MockWalletBalance.mock,
      tokens: MockTokens.all,
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadMockData();
  }
}

/// Dashboard provider
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});

/// Selected network provider
final selectedNetworkProvider = StateProvider<String>((ref) => 'Sepolia');
