import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import '../../../../core/constants/env_config.dart';
import '../../../../core/constants/mock_config.dart';
import '../../../../shared/providers/network_provider.dart';
import '../../domain/entities/nft.dart';
import '../../domain/entities/nft_attribute.dart';
import 'mock_nft_datasource.dart';

part 'nft_remote_datasource.g.dart';

abstract class NftRemoteDataSource {
  Future<List<Nft>> getNfts(String ownerAddress);
}

class NftRemoteDataSourceImpl implements NftRemoteDataSource {
  final Dio _dio;
  final NetworkType _network;

  NftRemoteDataSourceImpl(this._dio, this._network);

  @override
  Future<List<Nft>> getNfts(String ownerAddress) async {
    final baseUrl = EnvConfig.getNftApiUrl(_network);
    final url = '$baseUrl/getNFTs';

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'owner': ownerAddress,
          'withMetadata': 'true',
        },
      );

      final data = response.data;
      final List<dynamic> ownedNfts = data['ownedNfts'] as List<dynamic>;

      return ownedNfts.map<Nft>((json) {
        final contract = json['contract'];
        final contractAddress = contract['address'] as String;
        final collectionName = contract['name'] as String? ?? 'Unknown Collection';
        final id = json['id'];
        final tokenId = id['tokenId'] as String;
        final metadata = json['metadata'] ?? {};
        final title = json['title'] as String? ?? metadata['name'] as String? ?? 'Untitled';
        final description = json['description'] as String? ?? metadata['description'] as String? ?? '';
        
        // Handling Image URL (Alchemy usually provides media array)
        String imageUrl = '';
        final media = json['media'] as List<dynamic>?;
        if (media != null && media.isNotEmpty) {
           imageUrl = media[0]['gateway'] as String? ?? '';
        }
        if (imageUrl.isEmpty) {
            imageUrl = metadata['image'] as String? ?? '';
        }
        
        // Determine type
        final tokenTypeStr = id['tokenMetadata']?['tokenType'] as String? ?? 'UNKNOWN';
        NftType type = NftType.unknown;
        if (tokenTypeStr == 'ERC721') type = NftType.erc721;
        if (tokenTypeStr == 'ERC1155') type = NftType.erc1155;

        // Balance (for ERC1155)
        final balanceStr = json['balance'] as String?;
        final balance = balanceStr != null ? int.tryParse(balanceStr) : 1;

        // Parse attributes
        final List<NftAttribute> attributes = [];
        if (metadata['attributes'] != null) {
          final attrs = metadata['attributes'] as List<dynamic>;
          for (var attr in attrs) {
             if (attr is Map<String, dynamic>) {
               attributes.add(NftAttribute(
                 traitType: attr['trait_type'] as String? ?? '',
                 value: attr['value']?.toString() ?? '',
               ));
             }
          }
        }

        return Nft(
          contractAddress: contractAddress,
          tokenId: tokenId,
          title: title,
          description: description,
          collectionName: collectionName,
          imageUrl: _sanitizeIpfsUrl(imageUrl),
          type: type,
          balance: balance,
          attributes: attributes,
        );
      }).toList();

    } catch (e) {
      throw Exception('Failed to fetch NFTs: $e');
    }
  }

  String _sanitizeIpfsUrl(String url) {
    if (url.startsWith('ipfs://')) {
      return url.replaceFirst('ipfs://', 'https://ipfs.io/ipfs/');
    }
    return url;
  }
}

@riverpod
NftRemoteDataSource nftRemoteDataSource(Ref ref) {
  // 목업 모드일 경우 MockNftDataSource 사용
  if (MockConfig.useMockData || MockConfig.mockNft) {
    return MockNftDataSource();
  }

  final network = ref.watch(selectedNetworkProvider);
  final dio = Dio();
  return NftRemoteDataSourceImpl(dio, network);
}
