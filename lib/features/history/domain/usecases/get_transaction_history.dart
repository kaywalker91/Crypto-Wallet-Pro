import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/env_config.dart';
import '../entities/transaction_entity.dart';
import '../repositories/history_repository.dart';

class GetTransactionHistory {
  final HistoryRepository repository;

  GetTransactionHistory(this.repository);

  Future<Either<Failure, List<TransactionEntity>>> call({
    required String address,
    required NetworkType network,
  }) {
    return repository.getTransactionHistory(address: address, network: network);
  }
}
