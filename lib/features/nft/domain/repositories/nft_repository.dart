import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/nft.dart';

abstract class NftRepository {
  Future<Either<Failure, List<Nft>>> getNfts(String ownerAddress);
}
