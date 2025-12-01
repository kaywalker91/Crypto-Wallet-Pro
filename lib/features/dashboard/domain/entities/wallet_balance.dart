import 'package:equatable/equatable.dart';

/// Wallet balance entity
class WalletBalance extends Equatable {
  final String address;
  final String? ensName;
  final String balanceEth;
  final String balanceUsd;
  final String network;

  const WalletBalance({
    required this.address,
    this.ensName,
    required this.balanceEth,
    required this.balanceUsd,
    required this.network,
  });

  /// Shortened address for display (0x1234...5678)
  String get shortAddress {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  /// Display name (ENS name or short address)
  String get displayName => ensName ?? shortAddress;

  @override
  List<Object?> get props => [
        address,
        ensName,
        balanceEth,
        balanceUsd,
        network,
      ];
}

/// Mock wallet balance for development
class MockWalletBalance {
  MockWalletBalance._();

  static const WalletBalance mock = WalletBalance(
    address: '0x742d35Cc6634C0532925a3b844Bc9e7595f8fE2d',
    ensName: null,
    balanceEth: '0.5234 ETH',
    balanceUsd: '\$1,237.65',
    network: 'Sepolia',
  );
}
