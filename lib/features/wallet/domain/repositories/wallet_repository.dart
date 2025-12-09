import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/wallet.dart';

/// Repository contract for wallet creation, import, and persistence.
abstract class WalletRepository {
  Future<Either<Failure, String>> generateMnemonic();
  Future<Either<Failure, Wallet>> createWallet({String? mnemonic});
  Future<Either<Failure, Wallet>> importWallet(String mnemonic);
  Future<Either<Failure, Wallet?>> getStoredWallet();
  Future<Either<Failure, void>> deleteWallet();
  Future<Either<Failure, String>> getStoredMnemonic();
}
