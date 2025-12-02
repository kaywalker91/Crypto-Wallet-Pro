import 'package:equatable/equatable.dart';

import 'nft_attribute.dart';

/// NFT token type enum
enum NftTokenType {
  erc721,
  erc1155,
}

/// NFT entity representing an ERC-721 or ERC-1155 token
class Nft extends Equatable {
  final String tokenId;
  final String contractAddress;
  final String name;
  final String? description;
  final String imageUrl;
  final String? animationUrl;
  final String collectionName;
  final NftTokenType tokenType;
  final int quantity; // For ERC-1155, defaults to 1 for ERC-721
  final List<NftAttribute> attributes;
  final String? externalUrl;
  final String? backgroundColor;

  const Nft({
    required this.tokenId,
    required this.contractAddress,
    required this.name,
    this.description,
    required this.imageUrl,
    this.animationUrl,
    required this.collectionName,
    required this.tokenType,
    this.quantity = 1,
    this.attributes = const [],
    this.externalUrl,
    this.backgroundColor,
  });

  /// Check if this is an ERC-1155 token
  bool get isErc1155 => tokenType == NftTokenType.erc1155;

  /// Check if this NFT has animation
  bool get hasAnimation => animationUrl != null && animationUrl!.isNotEmpty;

  @override
  List<Object?> get props => [
        tokenId,
        contractAddress,
        name,
        description,
        imageUrl,
        animationUrl,
        collectionName,
        tokenType,
        quantity,
        attributes,
        externalUrl,
        backgroundColor,
      ];
}

/// Mock NFTs for development and UI testing
class MockNfts {
  MockNfts._();

  static const Nft boredApe1 = Nft(
    tokenId: '7537',
    contractAddress: '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D',
    name: 'Bored Ape #7537',
    description:
        'The Bored Ape Yacht Club is a collection of 10,000 unique Bored Ape NFTs.',
    imageUrl: 'https://picsum.photos/seed/ape1/400/400',
    collectionName: 'Bored Ape Yacht Club',
    tokenType: NftTokenType.erc721,
    attributes: [
      NftAttribute(traitType: 'Background', value: 'Orange', rarity: 12.5),
      NftAttribute(traitType: 'Fur', value: 'Golden Brown', rarity: 8.2),
      NftAttribute(traitType: 'Eyes', value: 'Bored', rarity: 15.3),
      NftAttribute(traitType: 'Clothes', value: 'Sailor Shirt', rarity: 4.1),
      NftAttribute(traitType: 'Mouth', value: 'Grin', rarity: 7.8),
    ],
    externalUrl: 'https://opensea.io/assets/ethereum/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d/7537',
  );

  static const Nft azuki1 = Nft(
    tokenId: '4521',
    contractAddress: '0xED5AF388653567Af2F388E6224dC7C4b3241C544',
    name: 'Azuki #4521',
    description:
        'Azuki starts with a collection of 10,000 avatars that give you membership access to The Garden.',
    imageUrl: 'https://picsum.photos/seed/azuki1/400/400',
    collectionName: 'Azuki',
    tokenType: NftTokenType.erc721,
    attributes: [
      NftAttribute(traitType: 'Type', value: 'Human', rarity: 45.0),
      NftAttribute(traitType: 'Hair', value: 'Pink Hairband', rarity: 3.2),
      NftAttribute(traitType: 'Clothing', value: 'Kimono', rarity: 6.5),
      NftAttribute(traitType: 'Eyes', value: 'Determined', rarity: 9.1),
      NftAttribute(traitType: 'Background', value: 'Off White A', rarity: 22.0),
    ],
    externalUrl: 'https://opensea.io/assets/ethereum/0xed5af388653567af2f388e6224dc7c4b3241c544/4521',
  );

  static const Nft doodle1 = Nft(
    tokenId: '2891',
    contractAddress: '0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e',
    name: 'Doodle #2891',
    description:
        'A community-driven collectibles project featuring art by Burnt Toast.',
    imageUrl: 'https://picsum.photos/seed/doodle1/400/400',
    collectionName: 'Doodles',
    tokenType: NftTokenType.erc721,
    backgroundColor: '#E5F0FF',
    attributes: [
      NftAttribute(traitType: 'Face', value: 'Happy', rarity: 18.2),
      NftAttribute(traitType: 'Hair', value: 'Blue Mohawk', rarity: 2.8),
      NftAttribute(traitType: 'Body', value: 'Purple Sweater', rarity: 5.4),
      NftAttribute(traitType: 'Background', value: 'Blue', rarity: 14.0),
      NftAttribute(traitType: 'Piercing', value: 'Gold Hoop', rarity: 7.3),
    ],
    externalUrl: 'https://opensea.io/assets/ethereum/0x8a90cab2b38dba80c64b7734e58ee1db38b8992e/2891',
  );

  static const Nft cloneX1 = Nft(
    tokenId: '15234',
    contractAddress: '0x49cF6f5d44E70224e2E23fDcdd2C053F30aDA28B',
    name: 'CloneX #15234',
    description: '20,000 next-gen Avatars, by RTFKT and Takashi Murakami.',
    imageUrl: 'https://picsum.photos/seed/clonex1/400/400',
    collectionName: 'CloneX',
    tokenType: NftTokenType.erc721,
    attributes: [
      NftAttribute(traitType: 'DNA', value: 'Human', rarity: 35.0),
      NftAttribute(traitType: 'Eye Color', value: 'Blue Eye', rarity: 12.1),
      NftAttribute(traitType: 'Hair', value: 'Punk Pink', rarity: 4.5),
      NftAttribute(traitType: 'Clothing', value: 'RTFKT Jacket', rarity: 8.9),
    ],
    externalUrl: 'https://opensea.io/assets/ethereum/0x49cf6f5d44e70224e2e23fdcdd2c053f30ada28b/15234',
  );

  static const Nft pudgyPenguin1 = Nft(
    tokenId: '6789',
    contractAddress: '0xBd3531dA5CF5857e7CfAA92426877b022e612cf8',
    name: 'Pudgy Penguin #6789',
    description:
        'Pudgy Penguins is a collection of 8,888 NFTs, waddling through Web3.',
    imageUrl: 'https://picsum.photos/seed/pudgy1/400/400',
    collectionName: 'Pudgy Penguins',
    tokenType: NftTokenType.erc721,
    attributes: [
      NftAttribute(traitType: 'Background', value: 'Blue', rarity: 20.5),
      NftAttribute(traitType: 'Skin', value: 'Normal', rarity: 55.0),
      NftAttribute(traitType: 'Face', value: 'Sunglasses', rarity: 6.2),
      NftAttribute(traitType: 'Head', value: 'Beanie', rarity: 4.8),
    ],
    externalUrl: 'https://opensea.io/assets/ethereum/0xbd3531da5cf5857e7cfaa92426877b022e612cf8/6789',
  );

  static const Nft artBlocks1 = Nft(
    tokenId: '78000123',
    contractAddress: '0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270',
    name: 'Chromie Squiggle #123',
    description:
        'Simple and easily identifiable, each Squiggle embodies the soul of the Art Blocks platform.',
    imageUrl: 'https://picsum.photos/seed/squiggle1/400/400',
    collectionName: 'Art Blocks',
    tokenType: NftTokenType.erc721,
    attributes: [
      NftAttribute(traitType: 'Color', value: 'Hyper Rainbow', rarity: 0.8),
      NftAttribute(traitType: 'Segments', value: '12', displayType: 'number'),
      NftAttribute(traitType: 'Steps Between', value: '200', displayType: 'number'),
    ],
    externalUrl: 'https://opensea.io/assets/ethereum/0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270/78000123',
  );

  // ERC-1155 example
  static const Nft openSeaShared1 = Nft(
    tokenId: '12345678901234567890',
    contractAddress: '0x495f947276749Ce646f68AC8c248420045cb7b5e',
    name: 'Crypto Art Collection #42',
    description: 'A unique piece from the Crypto Art Collection on OpenSea.',
    imageUrl: 'https://picsum.photos/seed/opensea1/400/400',
    collectionName: 'OpenSea Shared',
    tokenType: NftTokenType.erc1155,
    quantity: 5,
    attributes: [
      NftAttribute(traitType: 'Artist', value: 'CryptoArtist'),
      NftAttribute(traitType: 'Edition', value: '5/100'),
      NftAttribute(traitType: 'Year', value: '2024'),
    ],
  );

  static const Nft ens1 = Nft(
    tokenId: '84532971453826283098326834827394827',
    contractAddress: '0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85',
    name: 'vitalik.eth',
    description: 'Ethereum Name Service domain.',
    imageUrl: 'https://picsum.photos/seed/ens1/400/400',
    collectionName: 'ENS: Ethereum Name Service',
    tokenType: NftTokenType.erc721,
    attributes: [
      NftAttribute(traitType: 'Length', value: '7', displayType: 'number'),
      NftAttribute(traitType: 'Registration Date', value: '2017-06-19'),
      NftAttribute(traitType: 'Expiration Date', value: '2030-06-19'),
    ],
  );

  static const List<Nft> all = [
    boredApe1,
    azuki1,
    doodle1,
    cloneX1,
    pudgyPenguin1,
    artBlocks1,
    openSeaShared1,
    ens1,
  ];
}
