import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../shared/providers/network_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/datasources/history_remote_datasource.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/get_transaction_history.dart';

// DI
final historyRemoteDataSourceProvider = Provider<HistoryRemoteDataSource>((ref) {
  return HistoryRemoteDataSourceImpl(http.Client());
});

final historyRepositoryProvider = Provider((ref) {
  return HistoryRepositoryImpl(ref.watch(historyRemoteDataSourceProvider));
});

final getTransactionHistoryUseCaseProvider = Provider((ref) {
  return GetTransactionHistory(ref.watch(historyRepositoryProvider));
});

// Notifier
class HistoryNotifier extends AsyncNotifier<List<TransactionEntity>> {
  late GetTransactionHistory _getHistory;

  @override
  Future<List<TransactionEntity>> build() async {
    _getHistory = ref.watch(getTransactionHistoryUseCaseProvider);
    
    final walletState = ref.watch(walletProvider);
    final wallet = walletState.valueOrNull?.wallet;
    final network = ref.watch(selectedNetworkProvider);

    if (wallet == null) {
      return [];
    }

    return _fetchHistory(wallet.address, network);
  }

  Future<List<TransactionEntity>> _fetchHistory(String address, dynamic network) async {
    final result = await _getHistory(address: address, network: network);
    return result.fold(
      (failure) => throw failure,
      (history) => history,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final wallet = ref.read(walletViewProvider).wallet;
      final network = ref.read(selectedNetworkProvider);
      if (wallet == null) return [];
      return _fetchHistory(wallet.address, network);
    });
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<TransactionEntity>>(HistoryNotifier.new);
