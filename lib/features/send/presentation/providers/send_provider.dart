import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gas_estimate.dart';
import '../../domain/usecases/transaction_usecases.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/domain/usecases/get_private_key.dart';
import '../../../dashboard/domain/entities/token.dart';

// ✅ CLEAN ARCHITECTURE: Repository Provider는 별도 파일로 분리
// - Presentation Layer에서 Data Layer 직접 참조 제거
// - send_repository_providers.dart에서 제공
import 'send_repository_providers.dart';

// UseCases Providers
final sendTransactionUseCaseProvider = Provider<SendTransaction>((ref) {
  final repository = ref.watch(transactionRepositoryDomainProvider);
  return SendTransaction(repository);
});

final getGasEstimatesUseCaseProvider = Provider<GetGasEstimates>((ref) {
  final repository = ref.watch(transactionRepositoryDomainProvider);
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
  final GetPrivateKey _getPrivateKey;
  final Ref _ref;

  SendNotifier(
    this._sendTransaction,
    this._getGasEstimates,
    this._getPrivateKey,
    this._ref,
  ) : super(const SendState());

  Future<void> estimateGas({
    required String recipientAddress,
    required String amountEth,
    Token? token,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final walletState = await _ref.read(walletProvider.future);
      if (walletState.wallet == null) throw Exception("Wallet not found");

      final decimals = token?.decimals ?? 18;
      final amountWei = BigInt.from(double.parse(amountEth) * BigInt.from(10).pow(decimals).toDouble());

      final result = await _getGasEstimates(
        senderAddress: walletState.wallet!.address,
        recipientAddress: recipientAddress,
        amountInWei: amountWei,
        tokenAddress: token?.contractAddress,
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
    Token? token,
  }) async {
    if (state.gasEstimates == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final walletState = await _ref.read(walletProvider.future);
      if (walletState.wallet == null) throw Exception("Wallet not found");

      final decimals = token?.decimals ?? 18;
      final amountWei = BigInt.from(double.parse(amountEth) * BigInt.from(10).pow(decimals).toDouble());
      final estimate = state.gasEstimates![state.selectedPriority]!;

      final params = SendTransactionParams(
        senderAddress: walletState.wallet!.address,
        recipientAddress: recipientAddress,
        amountInWei: amountWei,
        gasEstimate: estimate,
        tokenAddress: token?.contractAddress,
      );

      // ✅ SECURITY: Private Key 메모리 노출 최소화
      // - 변수 스코프를 최소화하여 메모리 상주 시간 단축
      // - fold 내부에서 직접 트랜잭션 실행으로 중간 변수 제거
      final privateKeyResult = await _getPrivateKey();
      final result = await privateKeyResult.fold(
        (failure) async => throw Exception(failure.message),
        (privateKey) async {
          // Private Key를 최소 스코프 내에서만 사용
          final txResult = await _sendTransaction(
            params: params,
            privateKey: privateKey,
          );
          // privateKey는 이 클로저 스코프 종료 시 참조 해제됨
          return txResult;
        },
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
    ref.watch(getPrivateKeyUseCaseProvider),
    ref,
  );
});
