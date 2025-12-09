import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class CreateWallet {
  CreateWallet(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, Wallet>> call({String? mnemonic}) {
    return _repository.createWallet(mnemonic: mnemonic);
  }
}
