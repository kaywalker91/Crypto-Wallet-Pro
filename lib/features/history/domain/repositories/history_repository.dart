import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/transaction_entity.dart';
import '../../../../core/constants/env_config.dart';

abstract class HistoryRepository {
  Future<Either<Failure, List<TransactionEntity>>> getTransactionHistory({
    required String address,
    required NetworkType network,
  });
}
