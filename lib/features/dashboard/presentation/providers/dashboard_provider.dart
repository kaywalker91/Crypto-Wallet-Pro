
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/env_config.dart';
import '../../../../shared/providers/network_provider.dart';
import '../../domain/entities/token.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../data/repositories/balance_repository_impl.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

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
  final Ref ref;

  DashboardNotifier(this.ref) : super(const DashboardState(isLoading: true)) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    // Get current wallet address
    final walletState = await ref.read(walletProvider.future);
    final wallet = walletState.wallet;

    if (wallet == null) {
      state = state.copyWith(
        isLoading: false,
        error: "No wallet found",
      );
      return;
    }

    // Fetch ETH balance
    final balanceRepo = ref.read(balanceRepositoryProvider);
    final result = await balanceRepo.getEthBalance(wallet.address);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (balanceWei) async {
        // Convert Wei to ETH (1 ETH = 10^18 Wei)
        final ethBalance = balanceWei.toDouble() / 1e18;
        final network = ref.read(selectedNetworkProvider);
        final formattedBalance = ethBalance.toStringAsFixed(4);
        final networkLabel = network == NetworkType.mainnet
            ? 'Ethereum Mainnet'
            : 'Sepolia Testnet';
        
        // Fetch Token List
        final tokensResult = await balanceRepo.getTokens(wallet.address);
        final tokens = tokensResult.fold(
          (failure) => <Token>[], // Return empty list on failure for now, or MockTokens.all as fallback
          (tokens) => tokens,
        );

        state = state.copyWith(
          isLoading: false,
          walletBalance: WalletBalance(
            address: wallet.address,
            ensName: wallet.ensName,
            balanceEth: '$formattedBalance ETH',
            balanceUsd: '\$0.00', // TODO: Replace with real pricing data
            network: networkLabel,
          ),
          tokens: tokens, // Use real tokens
        );
      },
    );
  }

  Future<void> refresh() async {
    await loadData();
  }
}

/// Dashboard provider
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});

// Remove local selectedNetworkProvider since we have a shared one now
// final selectedNetworkProvider = StateProvider<String>((ref) => 'Sepolia');
