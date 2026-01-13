import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/storage_providers.dart';
import '../../data/datasources/wallet_local_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/create_wallet.dart';
import '../../domain/usecases/delete_wallet.dart';
import '../../domain/usecases/generate_mnemonic.dart';
import '../../domain/usecases/get_stored_wallet.dart';
import '../../domain/usecases/import_wallet.dart';
import '../../domain/usecases/get_private_key.dart';
import 'wallet_service_providers.dart';

// ============================================================================
// Data Layer Providers (DI)
// ============================================================================

/// Wallet Local DataSource Provider
/// 
/// 로컬 저장소(Secure Storage)에 대한 접근을 제공합니다.
final walletLocalDataSourceProvider = Provider<WalletLocalDataSource>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final authSession = ref.watch(authSessionServiceProvider);
  return WalletLocalDataSourceImpl(storage, authSession);
});

/// Wallet Repository Provider
///
/// Domain Layer의 Repository 인터페이스 구현체를 주입합니다.
/// ✅ SECURITY: AuthSessionService 주입으로 민감 데이터 접근 시 인증 강제
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final local = ref.watch(walletLocalDataSourceProvider);
  final authSession = ref.watch(authSessionServiceProvider);
  return WalletRepositoryImpl(local, authSession);
});

// ============================================================================
// Use Case Providers
// ============================================================================

/// Create Wallet Use Case Provider
final createWalletUseCaseProvider = Provider<CreateWallet>((ref) => 
    CreateWallet(ref.watch(walletRepositoryProvider)));

/// Generate Mnemonic Use Case Provider
final generateMnemonicUseCaseProvider = Provider<GenerateMnemonic>((ref) => 
    GenerateMnemonic(ref.watch(walletRepositoryProvider)));

/// Import Wallet Use Case Provider
final importWalletUseCaseProvider = Provider<ImportWallet>((ref) => 
    ImportWallet(ref.watch(walletRepositoryProvider)));

/// Get Stored Wallet Use Case Provider
final getStoredWalletUseCaseProvider = Provider<GetStoredWallet>((ref) => 
    GetStoredWallet(ref.watch(walletRepositoryProvider)));

/// Delete Wallet Use Case Provider
final deleteWalletUseCaseProvider = Provider<DeleteWallet>((ref) => 
    DeleteWallet(ref.watch(walletRepositoryProvider)));

/// Get Private Key Use Case Provider
/// 
/// 트랜잭션 서명 등에 사용되는 Private Key를 조회합니다.
/// 보안상 중요한 작업이므로 인증이 필요합니다.
final getPrivateKeyUseCaseProvider = Provider<GetPrivateKey>((ref) => 
    GetPrivateKey(ref.watch(walletRepositoryProvider)));
