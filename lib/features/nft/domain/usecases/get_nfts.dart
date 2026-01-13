import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/nft.dart';
import '../repositories/nft_repository.dart';

/// Use Case: NFT 목록 조회
/// 
/// 지갑 주소를 기반으로 사용자가 소유한 NFT(ERC-721, ERC-1155) 목록을 조회합니다.
/// Alchemy API를 통해 온체인 데이터를 가져옵니다.
class GetNfts {
  const GetNfts(this._repository);

  final NftRepository _repository;

  /// NFT 목록을 조회합니다.
  /// 
  /// [ownerAddress] - 지갑 주소 (Ethereum address format)
  /// 
  /// Returns:
  /// - [Right<List<Nft>>]: 성공 시 NFT 목록
  /// - [Left<Failure>]: 실패 시 에러 정보
  Future<Either<Failure, List<Nft>>> call(String ownerAddress) {
    return _repository.getNfts(ownerAddress);
  }
}
