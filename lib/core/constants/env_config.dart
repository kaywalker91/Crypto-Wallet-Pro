
enum NetworkType { mainnet, sepolia }

class EnvConfig {
  // TODO: Replace with your actual Alchemy API Key
  static const String alchemyApiKey = 'YOUR_ALCHEMY_API_KEY';
  
  // TODO: Replace with your WalletConnect Project ID (cloud.walletconnect.com)
  static const String walletConnectProjectId = 'b396378b9fc681d9b6e8b41787351e70';

  static String getRpcUrl(NetworkType network) {
    switch (network) {
      case NetworkType.mainnet:
        return 'https://eth-mainnet.g.alchemy.com/v2/$alchemyApiKey';
      case NetworkType.sepolia:
        return 'https://eth-sepolia.g.alchemy.com/v2/$alchemyApiKey';
    }
  }
}
