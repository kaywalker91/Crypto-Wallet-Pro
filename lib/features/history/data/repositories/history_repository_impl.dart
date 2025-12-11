import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/env_config.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource remoteDataSource;

  HistoryRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactionHistory({
    required String address,
    required NetworkType network,
  }) async {
    try {
      // Fetch Sent and Received transactions in parallel
      final results = await Future.wait([
        remoteDataSource.getTransfers(
          network: network,
          fromAddress: address,
          userAddressForParsing: address,
        ),
        remoteDataSource.getTransfers(
          network: network,
          toAddress: address,
          userAddressForParsing: address,
        ),
      ]);

      final sent = results[0];
      final received = results[1];

      // Merge list
      final allTransactions = [...sent, ...received];

      // Sort by timestamp descending (newest first)
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return Right(allTransactions);
    } on ServerException {
      return Left(ServerFailure('Failed to fetch transaction history'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
