
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/gas_estimate.dart';
import '../../domain/usecases/transaction_usecases.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/data/datasources/wallet_local_datasource.dart';

// UseCases Providers
final sendTransactionUseCaseProvider = Provider<SendTransaction>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return SendTransaction(repository);
});

final getGasEstimatesUseCaseProvider = Provider<GetGasEstimates>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetGasEstimates(repository);
});

// State
class SendState {
  final bool isLoading;
  final String? error;
  final Map<GasPriority, GasEstimate>? gasEstimates;
  final GasPriority selectedPriority;
  final String? txHash;

  const SendState({
    this.isLoading = false,
    this.error,
    this.gasEstimates,
    this.selectedPriority = GasPriority.medium,
    this.txHash,
  });

  SendState copyWith({
    bool? isLoading,
    String? error,
    Map<GasPriority, GasEstimate>? gasEstimates,
    GasPriority? selectedPriority,
    String? txHash,
  }) {
    return SendState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      gasEstimates: gasEstimates ?? this.gasEstimates,
      selectedPriority: selectedPriority ?? this.selectedPriority,
      txHash: txHash ?? this.txHash,
    );
  }
}

// Notifier
class SendNotifier extends StateNotifier<SendState> {
  final SendTransaction _sendTransaction;
  final GetGasEstimates _getGasEstimates;
  final Ref _ref;

  SendNotifier(
    this._sendTransaction,
    this._getGasEstimates,
    this._ref,
  ) : super(const SendState());

  Future<void> estimateGas({
    required String recipientAddress,
    required String amountEth,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final walletState = await _ref.read(walletProvider.future);
      if (walletState.wallet == null) throw Exception("Wallet not found");

      final amountWei = BigInt.from(double.parse(amountEth) * 1e18);

      final result = await _getGasEstimates(
        senderAddress: walletState.wallet!.address,
        recipientAddress: recipientAddress,
        amountInWei: amountWei,
      );

      result.fold(
        (failure) => state = state.copyWith(isLoading: false, error: failure.message),
        (estimates) => state = state.copyWith(isLoading: false, gasEstimates: estimates),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectPriority(GasPriority priority) {
    state = state.copyWith(selectedPriority: priority);
  }

  Future<bool> send({
    required String recipientAddress,
    required String amountEth,
  }) async {
    if (state.gasEstimates == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final walletState = await _ref.read(walletProvider.future);
      if (walletState.wallet == null) throw Exception("Wallet not found");

      final amountWei = BigInt.from(double.parse(amountEth) * 1e18);
      final estimate = state.gasEstimates![state.selectedPriority]!;

      // Retrieve Private Key (In a real app, we should use Biometric Auth confirmation here)
      final walletLocalDs = _ref.read(walletLocalDataSourceProvider);
      final privateKey = await walletLocalDs.retrievePrivateKey(); // Need to expose this or similar

      if (privateKey == null) throw Exception("Failed to retrieve private key");

      final params = SendTransactionParams(
        senderAddress: walletState.wallet!.address,
        recipientAddress: recipientAddress,
        amountInWei: amountWei,
        gasEstimate: estimate,
      );

      final result = await _sendTransaction(
        params: params,
        privateKey: privateKey,
      );

      return result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
        (hash) {
          state = state.copyWith(isLoading: false, txHash: hash);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final sendProvider = StateNotifierProvider.autoDispose<SendNotifier, SendState>((ref) {
  return SendNotifier(
    ref.watch(sendTransactionUseCaseProvider),
    ref.watch(getGasEstimatesUseCaseProvider),
    ref,
  );
});
