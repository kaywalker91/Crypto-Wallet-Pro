import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/wallet_repository.dart';

/// Use Case: Private Key 조회
/// 
/// 보안상 중요한 작업으로, 인증이 완료된 상태에서만 호출되어야 합니다.
/// 트랜잭션 서명 등 Private Key가 필요한 경우에만 사용합니다.
class GetPrivateKey {
  const GetPrivateKey(this._repository);

  final WalletRepository _repository;

  /// Private Key를 조회합니다.
  /// 
  /// Returns:
  /// - [Right<String>]: 성공 시 Private Key (hex format)
  /// - [Left<Failure>]: 실패 시 에러 정보
  Future<Either<Failure, String>> call() {
    return _repository.getPrivateKey();
  }
}
