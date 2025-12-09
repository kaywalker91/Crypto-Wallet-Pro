import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/wallet_repository.dart';

class DeleteWallet {
  DeleteWallet(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, void>> call() {
    return _repository.deleteWallet();
  }
}
