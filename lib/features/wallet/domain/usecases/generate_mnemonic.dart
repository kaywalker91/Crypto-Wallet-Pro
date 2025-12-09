import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/wallet_repository.dart';

class GenerateMnemonic {
  GenerateMnemonic(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, String>> call() {
    return _repository.generateMnemonic();
  }
}
