import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/repositories/transaction_repository_impl.dart';

// ============================================================================
// Repository Provider (DI Layer Abstraction)
// ============================================================================
//
// ✅ CLEAN ARCHITECTURE: Data Layer 의존성을 캡슐화
// - Presentation Layer는 이 파일만 import하여 Domain Interface에 접근
// - Data Layer 구현체 변경 시 이 파일만 수정하면 됨
// - 테스트 시 이 Provider를 override하여 Mock 주입 가능

/// Transaction Repository Provider
///
/// Domain Layer의 TransactionRepository 인터페이스를 제공합니다.
/// Data Layer 구현체(TransactionRepositoryImpl)를 주입합니다.
final transactionRepositoryDomainProvider = Provider<TransactionRepository>((ref) {
  return ref.watch(transactionRepositoryProvider);
});
