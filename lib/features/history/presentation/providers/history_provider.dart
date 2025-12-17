
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/network_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/get_transaction_history.dart';

part 'history_provider.g.dart';

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  @override
  FutureOr<List<TransactionEntity>> build() async {
    final walletState = await ref.watch(walletProvider.future);
    final wallet = walletState.wallet;
    final network = ref.watch(selectedNetworkProvider);

    if (wallet == null) {
      return [];
    }

    return _fetchHistory(wallet.address, network);
  }

  Future<List<TransactionEntity>> _fetchHistory(String address, dynamic network) async {
    final getHistory = ref.read(getTransactionHistoryUseCaseProvider);
    final result = await getHistory(address: address, network: network);
    
    return result.fold(
      (failure) => throw failure, // AsyncValue will catch this
      (history) => history,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    // Invalidate self to trigger rebuild
    ref.invalidateSelf();
    await future;
  }
}
