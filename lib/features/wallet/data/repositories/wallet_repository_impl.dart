import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../shared/services/auth_session_service.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_local_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._localDataSource, this._authSession);

  final WalletLocalDataSource _localDataSource;

  /// ✅ SECURITY: 인증 세션 서비스 (민감 데이터 접근 전 인증 강제)
  final AuthSessionService _authSession;

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
      // ✅ SECURITY: Mnemonic 접근 전 인증 강제
      final isAuthenticated = await _authSession.ensureAuthenticated(
        reason: '복구 구문 조회를 위해 인증이 필요합니다.',
      );
      if (!isAuthenticated) {
        return left(const AuthenticationFailure('인증이 필요합니다'));
      }

      final mnemonic = await _localDataSource.getMnemonic();
      if (mnemonic == null) {
        return left(const StorageFailure('No mnemonic found'));
      }
      return right(mnemonic);
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, String>> getPrivateKey() async {
    try {
      // ✅ SECURITY: Private Key 접근 전 인증 강제
      // - Defense-in-Depth: Repository Layer에서 인증 게이트 역할
      // - Domain Layer (UseCase)는 순수 비즈니스 로직만 유지
      final isAuthenticated = await _authSession.ensureAuthenticated(
        reason: '트랜잭션 서명을 위해 인증이 필요합니다.',
      );
      if (!isAuthenticated) {
        return left(const AuthenticationFailure('인증이 필요합니다'));
      }

      final privateKey = await _localDataSource.retrievePrivateKey();
      if (privateKey == null) {
        return left(const StorageFailure('Private key not found'));
      }
      return right(privateKey);
    } catch (e) {
      return left(_mapError(e));
    }
  }

  Failure _mapError(Object error) {
    if (error is Failure) return error;
    return Failure(error.toString());
  }
}
