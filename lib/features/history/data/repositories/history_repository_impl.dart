
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/env_config.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';

part 'history_repository_impl.g.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource _remoteDataSource;

  HistoryRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactionHistory({
    required String address,
    required NetworkType network,
  }) async {
    try {
      final transactions = await _remoteDataSource.getHistory(
        address: address,
        network: network,
      );
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to fetch transaction history'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

@riverpod
HistoryRepository historyRepository(Ref ref) {
  final remoteDataSource = ref.watch(historyRemoteDataSourceProvider);
  return HistoryRepositoryImpl(remoteDataSource);
}
