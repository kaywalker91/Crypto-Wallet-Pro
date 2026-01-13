import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/nft_repository.dart';
import '../../data/repositories/nft_repository_impl.dart';

/// NFT Repository Provider
/// 
/// Data Layer 구현체를 Domain Layer 인터페이스로 제공합니다.
/// 이를 통해 Presentation Layer는 Domain 인터페이스만 의존하고,
/// 실제 Data 구현은 이 Provider를 통해 주입받습니다.
/// 
/// 클린 아키텍처 의존성 규칙:
/// - Presentation → Domain ← Data
/// - Presentation은 Domain 인터페이스만 알고 있음
/// - Data 구현체는 이 Provider를 통해 주입됨
final nftRepositoryDomainProvider = Provider<NftRepository>((ref) {
  // Data Layer의 riverpod 생성 Provider를 통해 구현체를 가져옴
  return ref.watch(nftRepositoryProvider);
});
