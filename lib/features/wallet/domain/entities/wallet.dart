import 'package:equatable/equatable.dart';

/// Wallet entity representing a user's cryptocurrency wallet
class Wallet extends Equatable {
  final String address;
  final String? ensName;
  final DateTime createdAt;

  const Wallet({
    required this.address,
    this.ensName,
    required this.createdAt,
  });

  /// Shortened address for display (0x1234...5678)
  String get shortAddress {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  /// Display name (ENS name or short address)
  String get displayName => ensName ?? shortAddress;

  @override
  List<Object?> get props => [address, ensName, createdAt];
}

/// Mock wallet for development
class MockWallet {
  MockWallet._();

  static final Wallet mock = Wallet(
    address: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
    ensName: null,
    createdAt: DateTime.now(),
  );

  /// Test mnemonic (BIP-39 standard test vector)
  /// WARNING: Never use this in production!
  static const String mockMnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

  /// Mock mnemonic as word list
  static List<String> get mockMnemonicWords => mockMnemonic.split(' ');
}
