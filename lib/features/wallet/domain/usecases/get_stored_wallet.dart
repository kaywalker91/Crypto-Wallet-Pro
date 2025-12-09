import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class GetStoredWallet {
  GetStoredWallet(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, Wallet?>> call() {
    return _repository.getStoredWallet();
  }
}
