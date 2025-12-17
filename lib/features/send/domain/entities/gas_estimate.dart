
import 'package:equatable/equatable.dart';

enum GasPriority { low, medium, high }

class GasEstimate extends Equatable {
  final BigInt limit;
  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;
  final BigInt estimatedFeeInWei;

  const GasEstimate({
    required this.limit,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.estimatedFeeInWei,
  });

  @override
  List<Object?> get props => [limit, maxFeePerGas, maxPriorityFeePerGas, estimatedFeeInWei];
}

class SendTransactionParams extends Equatable {
  final String senderAddress;
  final String recipientAddress;
  final BigInt amountInWei; // Value to send
  final String? tokenAddress; // Optional: If sending ERC-20
  final GasEstimate gasEstimate;
  final String? privateKey; // Optional: If we want to sign directly, or we use repository internal signer

  const SendTransactionParams({
    required this.senderAddress,
     required this.recipientAddress,
    required this.amountInWei,
    required this.gasEstimate,
    this.tokenAddress,
    this.privateKey,
  });

  @override
  List<Object?> get props => [senderAddress, recipientAddress, amountInWei, gasEstimate, tokenAddress, privateKey];
}
