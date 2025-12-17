import 'package:equatable/equatable.dart';
import 'nft_attribute.dart';

enum NftType { erc721, erc1155, unknown }

class Nft extends Equatable {
  final String contractAddress;
  final String tokenId;
  final String title;
  final String description;
  final String collectionName;
  final String imageUrl;
  final NftType type;
  final int? balance; // For ERC-1155
  final List<NftAttribute> attributes;

  const Nft({
    required this.contractAddress,
    required this.tokenId,
    required this.title,
    required this.description,
    this.collectionName = '',
    required this.imageUrl,
    required this.type,
    this.balance,
    this.attributes = const [],
  });

  @override
  List<Object?> get props => [
        contractAddress,
        tokenId,
        title,
        description,
        collectionName,
        imageUrl,
        type,
        balance,
        attributes,
      ];
}
