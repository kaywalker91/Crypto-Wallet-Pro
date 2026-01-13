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
  
  /// Private Key를 조회합니다.
  /// 인증이 완료된 상태에서만 호출되어야 합니다.
  Future<Either<Failure, String>> getPrivateKey();
}
