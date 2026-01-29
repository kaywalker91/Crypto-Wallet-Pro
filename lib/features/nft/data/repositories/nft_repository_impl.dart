import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/nft.dart';
import '../../domain/repositories/nft_repository.dart';
import '../datasources/nft_remote_datasource.dart';

part 'nft_repository_impl.g.dart';

class NftRepositoryImpl implements NftRepository {
  final NftRemoteDataSource _remoteDataSource;

  NftRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Nft>>> getNfts(String ownerAddress) async {
    try {
      final nfts = await _remoteDataSource.getNfts(ownerAddress);
      return Right(nfts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

@riverpod
NftRepository nftRepository(Ref ref) {
  final remoteDataSource = ref.watch(nftRemoteDataSourceProvider);
  return NftRepositoryImpl(remoteDataSource);
}
