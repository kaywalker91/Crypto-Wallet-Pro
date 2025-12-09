import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class ImportWallet {
  ImportWallet(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, Wallet>> call(String mnemonic) {
    return _repository.importWallet(mnemonic);
  }
}
