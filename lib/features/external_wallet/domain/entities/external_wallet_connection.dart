import 'package:equatable/equatable.dart';

/// Represents a connection to an external wallet (e.g., MetaMask)
class ExternalWalletConnection extends Equatable {
  /// The wallet address
  final String address;

  /// The chain ID of the connected network
  final int chainId;

  /// The WalletConnect session topic for future requests
  final String sessionTopic;

  /// The wallet name (e.g., "MetaMask")
  final String walletName;

  /// Timestamp when the connection was established
  final DateTime connectedAt;

  const ExternalWalletConnection({
    required this.address,
    required this.chainId,
    required this.sessionTopic,
    required this.walletName,
    required this.connectedAt,
  });

  /// Check if this connection is for a specific chain
  bool isChain(int checkChainId) => chainId == checkChainId;

  /// Get abbreviated address for display
  String get abbreviatedAddress {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  List<Object?> get props => [address, chainId, sessionTopic, walletName, connectedAt];

  @override
  String toString() {
    return 'ExternalWalletConnection(address: $abbreviatedAddress, chainId: $chainId, wallet: $walletName)';
  }
}
