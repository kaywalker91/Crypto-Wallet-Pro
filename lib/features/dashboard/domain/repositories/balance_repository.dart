
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

import '../../domain/entities/token.dart';

abstract class BalanceRepository {
  Future<Either<Failure, BigInt>> getEthBalance(String address);
  Future<Either<Failure, BigInt>> getERC20Balance(String tokenAddress, String walletAddress);
  Future<Either<Failure, List<Token>>> getTokens(String walletAddress);
}
