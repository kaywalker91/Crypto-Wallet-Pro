import 'package:flutter_dotenv/flutter_dotenv.dart';

enum NetworkType { mainnet, sepolia }

class EnvConfig {
  static String get alchemyApiKey => dotenv.env['ALCHEMY_API_KEY'] ?? '';
  static String get walletConnectProjectId => dotenv.env['WALLET_CONNECT_PROJECT_ID'] ?? '';

  static String getRpcUrl(NetworkType network) {
    if (alchemyApiKey.isEmpty) {
      throw Exception('ALCHEMY_API_KEY is not found in .env file');
    }
    switch (network) {
      case NetworkType.mainnet:
        return 'https://eth-mainnet.g.alchemy.com/v2/$alchemyApiKey';
      case NetworkType.sepolia:
        return 'https://eth-sepolia.g.alchemy.com/v2/$alchemyApiKey';
    }
  }

  static String getNftApiUrl(NetworkType network) {
    if (alchemyApiKey.isEmpty) {
      throw Exception('ALCHEMY_API_KEY is not found in .env file');
    }
    switch (network) {
      case NetworkType.mainnet:
        return 'https://eth-mainnet.g.alchemy.com/nft/v2/$alchemyApiKey';
      case NetworkType.sepolia:
        return 'https://eth-sepolia.g.alchemy.com/nft/v2/$alchemyApiKey';
    }
  }
}
