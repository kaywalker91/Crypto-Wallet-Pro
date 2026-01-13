import '../../../../core/constants/mock_config.dart';
import '../../domain/entities/nft.dart';
import '../../domain/entities/nft_attribute.dart';
import 'nft_remote_datasource.dart';

/// 목업 NFT 데이터 소스
///
/// API 호출 없이 NFT 갤러리 기능을 테스트할 수 있도록 목업 데이터 제공
class MockNftDataSource implements NftRemoteDataSource {
  MockNftDataSource();

  @override
  Future<List<Nft>> getNfts(String ownerAddress) async {
    // 실제 API 응답 시간 시뮬레이션
    await Future.delayed(Duration(milliseconds: MockConfig.mockDelayMs));

    if (MockConfig.simulateErrors && _shouldFail()) {
      throw Exception('Mock: Failed to fetch NFTs');
    }

    return _mockNfts;
  }

  bool _shouldFail() {
    return DateTime.now().millisecondsSinceEpoch % 100 < (MockConfig.errorProbability * 100);
  }
}

/// 목업 NFT 데이터
final List<Nft> _mockNfts = [
  // Bored Ape style
  const Nft(
    contractAddress: '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D',
    tokenId: '1234',
    title: 'Bored Ape #1234',
    description: 'A bored ape living in the digital wilderness. Part of the exclusive BAYC collection.',
    collectionName: 'Bored Ape Yacht Club',
    imageUrl: 'https://picsum.photos/seed/bayc1234/400/400',
    type: NftType.erc721,
    balance: 1,
    attributes: [
      NftAttribute(traitType: 'Background', value: 'Blue'),
      NftAttribute(traitType: 'Fur', value: 'Golden Brown'),
      NftAttribute(traitType: 'Eyes', value: 'Bored'),
      NftAttribute(traitType: 'Clothes', value: 'Tuxedo'),
      NftAttribute(traitType: 'Hat', value: 'Seaman\'s Cap'),
      NftAttribute(traitType: 'Mouth', value: 'Grin'),
    ],
  ),
  // CryptoPunk style
  const Nft(
    contractAddress: '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB',
    tokenId: '7804',
    title: 'CryptoPunk #7804',
    description: 'One of the rarest CryptoPunks with alien features. A true gem of NFT history.',
    collectionName: 'CryptoPunks',
    imageUrl: 'https://picsum.photos/seed/punk7804/400/400',
    type: NftType.erc721,
    balance: 1,
    attributes: [
      NftAttribute(traitType: 'Type', value: 'Alien'),
      NftAttribute(traitType: 'Accessory', value: 'Cap Forward'),
      NftAttribute(traitType: 'Accessory', value: 'Pipe'),
      NftAttribute(traitType: 'Accessory', value: 'Small Shades'),
    ],
  ),
  // Art Blocks style
  const Nft(
    contractAddress: '0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270',
    tokenId: '78000123',
    title: 'Fidenza #123',
    description: 'A generative art piece from the Fidenza collection by Tyler Hobbs.',
    collectionName: 'Art Blocks - Fidenza',
    imageUrl: 'https://picsum.photos/seed/fidenza123/400/400',
    type: NftType.erc721,
    balance: 1,
    attributes: [
      NftAttribute(traitType: 'Color Palette', value: 'Luxe'),
      NftAttribute(traitType: 'Scale', value: 'Large'),
      NftAttribute(traitType: 'Turbulence', value: 'High'),
      NftAttribute(traitType: 'Super Blocks', value: 'Yes'),
    ],
  ),
  // Azuki style
  const Nft(
    contractAddress: '0xED5AF388653567Af2F388E6224dC7C4b3241C544',
    tokenId: '5555',
    title: 'Azuki #5555',
    description: 'A member of the Azuki universe. Ready for the garden.',
    collectionName: 'Azuki',
    imageUrl: 'https://picsum.photos/seed/azuki5555/400/400',
    type: NftType.erc721,
    balance: 1,
    attributes: [
      NftAttribute(traitType: 'Type', value: 'Human'),
      NftAttribute(traitType: 'Hair', value: 'Water'),
      NftAttribute(traitType: 'Clothing', value: 'Light Armor'),
      NftAttribute(traitType: 'Eyes', value: 'Striking'),
      NftAttribute(traitType: 'Mouth', value: 'Frown'),
      NftAttribute(traitType: 'Background', value: 'Off White A'),
    ],
  ),
  // Doodles style
  const Nft(
    contractAddress: '0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e',
    tokenId: '420',
    title: 'Doodle #420',
    description: 'A colorful hand-drawn doodle with unique traits.',
    collectionName: 'Doodles',
    imageUrl: 'https://picsum.photos/seed/doodle420/400/400',
    type: NftType.erc721,
    balance: 1,
    attributes: [
      NftAttribute(traitType: 'Face', value: 'Happy'),
      NftAttribute(traitType: 'Hair', value: 'Rainbow Afro'),
      NftAttribute(traitType: 'Body', value: 'Purple Hoodie'),
      NftAttribute(traitType: 'Background', value: 'Gradient Rainbow'),
      NftAttribute(traitType: 'Piercing', value: 'Gold Stud'),
    ],
  ),
  // ERC-1155 Gaming NFT
  const Nft(
    contractAddress: '0x495f947276749Ce646f68AC8c248420045cb7b5e',
    tokenId: '99887766554433221100',
    title: 'Legendary Sword of Destiny',
    description: 'A powerful sword forged in the fires of the blockchain. Grants +50 attack power.',
    collectionName: 'Crypto Warriors',
    imageUrl: 'https://picsum.photos/seed/sword99/400/400',
    type: NftType.erc1155,
    balance: 3,
    attributes: [
      NftAttribute(traitType: 'Rarity', value: 'Legendary'),
      NftAttribute(traitType: 'Attack', value: '50'),
      NftAttribute(traitType: 'Element', value: 'Fire'),
      NftAttribute(traitType: 'Level Required', value: '80'),
    ],
  ),
  // ERC-1155 Collectible
  const Nft(
    contractAddress: '0x495f947276749Ce646f68AC8c248420045cb7b5e',
    tokenId: '11223344556677889900',
    title: 'Gold Coin Pack',
    description: 'A pack of rare gold coins from the ancient crypto realm.',
    collectionName: 'Crypto Treasures',
    imageUrl: 'https://picsum.photos/seed/goldpack/400/400',
    type: NftType.erc1155,
    balance: 10,
    attributes: [
      NftAttribute(traitType: 'Rarity', value: 'Rare'),
      NftAttribute(traitType: 'Type', value: 'Consumable'),
      NftAttribute(traitType: 'Value', value: '1000 GP'),
    ],
  ),
  // Music NFT
  const Nft(
    contractAddress: '0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405',
    tokenId: '8888',
    title: 'Sonic Dreams #8888',
    description: 'An exclusive music NFT featuring a limited edition track.',
    collectionName: 'Sound XYZ',
    imageUrl: 'https://picsum.photos/seed/sonic8888/400/400',
    type: NftType.erc721,
    balance: 1,
    attributes: [
      NftAttribute(traitType: 'Artist', value: 'CryptoBeats'),
      NftAttribute(traitType: 'Genre', value: 'Electronic'),
      NftAttribute(traitType: 'Duration', value: '3:45'),
      NftAttribute(traitType: 'Edition', value: '1 of 100'),
    ],
  ),
  // ENS Domain
  const Nft(
    contractAddress: '0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85',
    tokenId: '38293829382938293829',
    title: 'vitalik.eth',
    description: 'A premium ENS domain name for decentralized identity.',
    collectionName: 'ENS: Ethereum Name Service',
    imageUrl: 'https://picsum.photos/seed/ens123/400/400',
    type: NftType.erc721,
    balance: 1,
    attributes: [
      NftAttribute(traitType: 'Registration Date', value: '2017-05-04'),
      NftAttribute(traitType: 'Expiration Date', value: '2099-05-04'),
      NftAttribute(traitType: 'Character Set', value: 'Alphanumeric'),
      NftAttribute(traitType: 'Length', value: '7'),
    ],
  ),
  // Loot style
  const Nft(
    contractAddress: '0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7',
    tokenId: '1337',
    title: 'Bag #1337',
    description: '"Divine Robe" of Giants\n"Grim Shout" Grave Wand of Skill +1\nHard Leather Armor\nWool Sash\nOrnate Greaves\nDragonskin Belt\nDemon Crown\nPlatinum Ring',
    collectionName: 'Loot (for Adventurers)',
    imageUrl: 'https://picsum.photos/seed/loot1337/400/400',
    type: NftType.erc721,
    balance: 1,
    attributes: [
      NftAttribute(traitType: 'Chest', value: 'Divine Robe of Giants'),
      NftAttribute(traitType: 'Weapon', value: 'Grim Shout Grave Wand of Skill +1'),
      NftAttribute(traitType: 'Head', value: 'Demon Crown'),
      NftAttribute(traitType: 'Ring', value: 'Platinum Ring'),
    ],
  ),
];
