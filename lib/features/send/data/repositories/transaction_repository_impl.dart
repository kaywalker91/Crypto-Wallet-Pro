
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/gas_estimate.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';

part 'transaction_repository_impl.g.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _remoteDataSource;

  TransactionRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, Map<GasPriority, GasEstimate>>> getGasEstimates({
    required String senderAddress,
    required String recipientAddress,
    required BigInt amountInWei,
    String? tokenAddress,
  }) async {
    try {
      final result = await _remoteDataSource.getGasEstimates(
        senderAddress: senderAddress,
        recipientAddress: recipientAddress,
        amountInWei: amountInWei,
        tokenAddress: tokenAddress,
      );
      return Right(result);
    } catch (e) {
      return Left(NetworkFailure('Failed to estimate gas', cause: e));
    }
  }

  @override
  Future<Either<Failure, String>> sendTransaction({
    required SendTransactionParams params,
    required String privateKey,
  }) async {
    try {
      final txHash = await _remoteDataSource.sendTransaction(
        params: params,
        privateKey: privateKey,
      );
      return Right(txHash);
    } catch (e) {
      return Left(NetworkFailure('Failed to send transaction', cause: e));
    }
  }
}

@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  final remote = ref.watch(transactionRemoteDataSourceProvider);
  return TransactionRepositoryImpl(remote);
}
