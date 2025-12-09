import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/credentials.dart' show EthPrivateKey;
import 'package:web3dart/crypto.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/wallet.dart';
import '../models/wallet_model.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../../../shared/services/auth_session_service.dart';

abstract class WalletLocalDataSource {
  Future<String> generateMnemonic();
  Future<EthPrivateKey> derivePrivateKey(String mnemonic);
  Future<Wallet> deriveWallet(String mnemonic);
  Future<void> saveMnemonic(String mnemonic);
  Future<String?> getMnemonic();
  Future<void> deleteMnemonic();
  Future<void> cacheWallet(Wallet wallet);
  Future<Wallet?> readCachedWallet();
  Future<void> clearAll();
}

class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  WalletLocalDataSourceImpl(
    this._storage,
    this._authSessionService,
  );

  final SecureStorageService _storage;
  final AuthSessionService _authSessionService;

  Future<void> _ensureAuth({String reason = '지갑 정보를 불러오려면 인증이 필요합니다.'}) async {
    final authed = await _authSessionService.ensureAuthenticated(reason: reason);
    if (!authed) {
      throw const StorageFailure('Authentication required');
    }
  }

  @override
  Future<String> generateMnemonic() async {
    try {
      return bip39.generateMnemonic(strength: 128);
    } catch (e) {
      throw ValidationFailure('Failed to generate mnemonic', cause: e);
    }
  }

  @override
  Future<EthPrivateKey> derivePrivateKey(String mnemonic) async {
    try {
      if (!bip39.validateMnemonic(mnemonic)) {
        throw const ValidationFailure('Invalid mnemonic phrase');
      }

      final seed = bip39.mnemonicToSeed(mnemonic);
      final root = bip32.BIP32.fromSeed(seed);
      final child = root.derivePath("m/44'/60'/0'/0/0");
      final privateKey = child.privateKey;
      if (privateKey == null) {
        throw const ValidationFailure('Failed to derive private key');
      }

      return EthPrivateKey.fromHex(
        bytesToHex(privateKey, include0x: true),
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw Failure('Failed to derive private key', cause: e);
    }
  }

  @override
  Future<Wallet> deriveWallet(String mnemonic) async {
    try {
      final ethKey = await derivePrivateKey(mnemonic);
      final address = await ethKey.extractAddress();

      return WalletModel(
        address: address.hexEip55,
        createdAt: DateTime.now().toUtc(),
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw Failure('Failed to derive wallet', cause: e);
    }
  }

  @override
  Future<void> saveMnemonic(String mnemonic) async {
    try {
      await _storage.write(key: StorageKeys.mnemonic, value: mnemonic);
    } catch (e) {
      throw StorageFailure('Failed to save mnemonic', cause: e);
    }
  }

  @override
  Future<String?> getMnemonic() async {
    try {
      await _ensureAuth();
      return _storage.read(StorageKeys.mnemonic);
    } catch (e) {
      throw StorageFailure('Failed to read mnemonic', cause: e);
    }
  }

  @override
  Future<void> deleteMnemonic() async {
    try {
      await _ensureAuth();
      await _storage.delete(StorageKeys.mnemonic);
    } catch (e) {
      throw StorageFailure('Failed to delete mnemonic', cause: e);
    }
  }

  @override
  Future<void> cacheWallet(Wallet wallet) async {
    try {
      final model = WalletModel.fromEntity(wallet);
      await _storage.write(key: StorageKeys.wallet, value: model.encode());
    } catch (e) {
      throw StorageFailure('Failed to cache wallet', cause: e);
    }
  }

  @override
  Future<Wallet?> readCachedWallet() async {
    try {
      // Wallet metadata is less sensitive; avoid forcing auth here to keep app boot smooth.
      final data = await _storage.read(StorageKeys.wallet);
      if (data == null) return null;
      return WalletModel.decode(data);
    } catch (e) {
      throw StorageFailure('Failed to read cached wallet', cause: e);
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _storage.delete(StorageKeys.wallet);
      await deleteMnemonic();
      await _authSessionService.clearSession();
    } catch (e) {
      throw StorageFailure('Failed to clear wallet storage', cause: e);
    }
  }
}
