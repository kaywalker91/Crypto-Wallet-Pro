
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/gas_estimate.dart';
import '../repositories/transaction_repository.dart';

class SendTransaction {
  final TransactionRepository _repository;

  SendTransaction(this._repository);

  Future<Either<Failure, String>> call({
    required SendTransactionParams params,
    required String privateKey,
  }) {
    return _repository.sendTransaction(params: params, privateKey: privateKey);
  }
}

class GetGasEstimates {
  final TransactionRepository _repository;

  GetGasEstimates(this._repository);

  Future<Either<Failure, Map<GasPriority, GasEstimate>>> call({
    required String senderAddress,
    required String recipientAddress,
    required BigInt amountInWei,
  }) {
    return _repository.getGasEstimates(
      senderAddress: senderAddress,
      recipientAddress: recipientAddress,
      amountInWei: amountInWei,
    );
  }
}
