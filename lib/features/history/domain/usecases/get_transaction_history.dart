
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/constants/env_config.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../entities/transaction_entity.dart';
import '../repositories/history_repository.dart';

part 'get_transaction_history.g.dart';

class GetTransactionHistory {
  final HistoryRepository _repository;

  GetTransactionHistory(this._repository);

  Future<Either<Failure, List<TransactionEntity>>> call({
    required String address,
    required NetworkType network,
  }) {
    return _repository.getTransactionHistory(address: address, network: network);
  }
}

@riverpod
GetTransactionHistory getTransactionHistoryUseCase(GetTransactionHistoryUseCaseRef ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return GetTransactionHistory(repository);
}
