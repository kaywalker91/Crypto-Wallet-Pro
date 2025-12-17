
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/gas_estimate.dart';

abstract class TransactionRepository {
  /// Estimate gas for a transaction
  Future<Either<Failure, Map<GasPriority, GasEstimate>>> getGasEstimates({
    required String senderAddress,
    required String recipientAddress,
    required BigInt amountInWei,
    String? tokenAddress,
  });

  /// Send transaction
  /// Returns transaction hash
  Future<Either<Failure, String>> sendTransaction({
    required SendTransactionParams params,
    required String privateKey,
  });
}
