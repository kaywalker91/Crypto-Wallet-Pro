
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import '../../../../core/error/failures.dart';
import '../datasources/balance_remote_datasource.dart';
import '../../domain/repositories/balance_repository.dart';
import '../../domain/entities/token.dart'; // Import MockTokens

part 'balance_repository_impl.g.dart';

class BalanceRepositoryImpl implements BalanceRepository {
  final BalanceRemoteDataSource _remoteDataSource;

  BalanceRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, BigInt>> getEthBalance(String address) async {
    try {
      final balance = await _remoteDataSource.getEthBalance(address);
      return Right(balance);
    } catch (e) {
      return Left(NetworkFailure('Failed to fetch ETH balance', cause: e));
    }
  }

  @override
  Future<Either<Failure, BigInt>> getERC20Balance(String tokenAddress, String walletAddress) async {
    try {
      final balance = await _remoteDataSource.getERC20Balance(tokenAddress, walletAddress);
      return Right(balance);
    } catch (e) {
      return Left(NetworkFailure('Failed to fetch ERC20 balance', cause: e));
    }
  }

  @override
  Future<Either<Failure, List<Token>>> getTokens(String walletAddress) async {
    try {
      final List<Token> tokensWithBalance = [];
      
      // Iterate through known tokens (MockTokens.all) and fetch real balances
      // In a real app, this list would come from an API or user-added tokens list
      for (final token in MockTokens.all) {
        if (token.symbol == 'ETH') {
          // ETH is already fetched separately in dashboard, but we include it here for completeness if needed
          // Or skip if UI handles ETH separately. For now, let's skip ETH here to avoid duplication or fetch it again.
          continue;
        }

        if (token.contractAddress != null) {
          try {
            final balanceWei = await _remoteDataSource.getERC20Balance(token.contractAddress!, walletAddress);
            final balanceEth = balanceWei.toDouble() / BigInt.from(10).pow(token.decimals).toDouble();
            
            // Only add tokens with non-zero balance or if user explicitly added them
            // For demo, we add all specific tokens
            tokensWithBalance.add(Token(
              symbol: token.symbol,
              name: token.name,
              balance: balanceEth.toStringAsFixed(4), // Formatting
              valueUsd: '\$0.00', // Pricing API needed
              color: token.color,
              contractAddress: token.contractAddress,
              decimals: token.decimals,
            ));
          } catch (e) {
            // If fetching fails for one token, we just skip it or log it
            // Don't fail the whole list
          }
        }
      }
      return Right(tokensWithBalance);
    } catch (e) {
      return Left(NetworkFailure('Failed to fetch token balances', cause: e));
    }
  }
}

@riverpod
BalanceRepository balanceRepository(Ref ref) {
  final remoteDataSource = ref.watch(balanceRemoteDataSourceProvider);
  return BalanceRepositoryImpl(remoteDataSource);
}
