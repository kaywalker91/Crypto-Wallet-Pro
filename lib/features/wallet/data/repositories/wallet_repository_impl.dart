import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_local_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._localDataSource);

  final WalletLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, String>> generateMnemonic() async {
    try {
      final mnemonic = await _localDataSource.generateMnemonic();
      return right(mnemonic);
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, Wallet>> createWallet({String? mnemonic}) async {
    try {
      final phrase = (mnemonic ?? await _localDataSource.generateMnemonic()).trim();
      final wallet = await _localDataSource.deriveWallet(phrase);
      await _localDataSource.saveMnemonic(phrase);
      await _localDataSource.cacheWallet(wallet);
      return right(wallet);
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, Wallet>> importWallet(String mnemonic) async {
    try {
      final cleanedMnemonic = mnemonic.trim();
      await _localDataSource.saveMnemonic(cleanedMnemonic);
      final wallet = await _localDataSource.deriveWallet(cleanedMnemonic);
      await _localDataSource.cacheWallet(wallet);
      return right(wallet);
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, Wallet?>> getStoredWallet() async {
    try {
      final wallet = await _localDataSource.readCachedWallet();
      return right(wallet);
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWallet() async {
    try {
      await _localDataSource.clearAll();
      return right(null);
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, String>> getStoredMnemonic() async {
    try {
      final mnemonic = await _localDataSource.getMnemonic();
      if (mnemonic == null) {
        return left(const StorageFailure('No mnemonic found'));
      }
      return right(mnemonic);
    } catch (e) {
      return left(_mapError(e));
    }
  }

  Failure _mapError(Object error) {
    if (error is Failure) return error;
    return Failure(error.toString());
  }
}
