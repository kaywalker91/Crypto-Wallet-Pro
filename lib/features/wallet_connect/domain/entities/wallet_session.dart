import 'package:equatable/equatable.dart';

import 'dapp_info.dart';

/// Session connection status
enum SessionStatus {
  active,
  expired,
  pending,
}

/// WalletConnect session entity
class WalletSession extends Equatable {
  final String id;
  final DappInfo dapp;
  final String chainId;
  final String chainName;
  final DateTime connectedAt;
  final DateTime? expiresAt;
  final SessionStatus status;
  final List<String> methods;
  final List<String> events;
  final String? walletAddress;

  const WalletSession({
    required this.id,
    required this.dapp,
    required this.chainId,
    required this.chainName,
    required this.connectedAt,
    this.expiresAt,
    required this.status,
    this.methods = const [],
    this.events = const [],
    this.walletAddress,
  });

  /// Check if session is active
  bool get isActive => status == SessionStatus.active;

  /// Check if session is expired
  bool get isExpired {
    if (status == SessionStatus.expired) return true;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return true;
    return false;
  }

  /// Check if session is pending approval
  bool get isPending => status == SessionStatus.pending;

  /// Get formatted connection duration
  String get connectionDuration {
    final duration = DateTime.now().difference(connectedAt);
    if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    }
    return 'Just now';
  }

  @override
  List<Object?> get props => [
        id,
        dapp,
        chainId,
        chainName,
        connectedAt,
        expiresAt,
        status,
        methods,
        events,
        walletAddress,
      ];
}

/// Mock sessions for development and UI testing
class MockSessions {
  MockSessions._();

  static final WalletSession uniswap = WalletSession(
    id: 'session_uniswap_001',
    dapp: const DappInfo(
      name: 'Uniswap',
      url: 'https://app.uniswap.org',
      iconUrl: 'https://app.uniswap.org/favicon.png',
      description: 'Swap, earn, and build on the leading decentralized crypto trading protocol.',
    ),
    chainId: 'eip155:1',
    chainName: 'Ethereum Mainnet',
    connectedAt: DateTime.now().subtract(const Duration(hours: 2)),
    expiresAt: DateTime.now().add(const Duration(days: 7)),
    status: SessionStatus.active,
    methods: ['eth_sendTransaction', 'eth_signTransaction', 'personal_sign', 'eth_signTypedData'],
    events: ['chainChanged', 'accountsChanged'],
    walletAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f5bB12',
  );

  static final WalletSession openSea = WalletSession(
    id: 'session_opensea_002',
    dapp: const DappInfo(
      name: 'OpenSea',
      url: 'https://opensea.io',
      iconUrl: 'assets/icons/logo_opensea.png',
      description: 'The largest NFT marketplace. Buy, sell, and discover rare digital items.',
    ),
    chainId: 'eip155:1',
    chainName: 'Ethereum Mainnet',
    connectedAt: DateTime.now().subtract(const Duration(days: 1)),
    expiresAt: DateTime.now().add(const Duration(days: 6)),
    status: SessionStatus.active,
    methods: ['eth_sendTransaction', 'personal_sign', 'eth_signTypedData_v4'],
    events: ['chainChanged', 'accountsChanged'],
    walletAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f5bB12',
  );

  static final WalletSession aave = WalletSession(
    id: 'session_aave_003',
    dapp: const DappInfo(
      name: 'Aave',
      url: 'https://app.aave.com',
      iconUrl: 'https://app.aave.com/favicon.ico',
      description: 'Aave is an open source liquidity protocol for earning interest on deposits.',
    ),
    chainId: 'eip155:1',
    chainName: 'Ethereum Mainnet',
    connectedAt: DateTime.now().subtract(const Duration(days: 7)),
    expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
    status: SessionStatus.expired,
    methods: ['eth_sendTransaction', 'personal_sign'],
    events: ['chainChanged', 'accountsChanged'],
    walletAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f5bB12',
  );

  static final WalletSession ens = WalletSession(
    id: 'session_ens_004',
    dapp: const DappInfo(
      name: 'ENS Domains',
      url: 'https://app.ens.domains',
      iconUrl: 'https://app.ens.domains/favicon.ico',
      description: 'Decentralised naming for wallets, websites, & more.',
    ),
    chainId: 'eip155:1',
    chainName: 'Ethereum Mainnet',
    connectedAt: DateTime.now(),
    status: SessionStatus.pending,
    methods: ['eth_sendTransaction', 'personal_sign', 'eth_signTypedData'],
    events: ['chainChanged', 'accountsChanged'],
  );

  static final WalletSession lido = WalletSession(
    id: 'session_lido_005',
    dapp: const DappInfo(
      name: 'Lido',
      url: 'https://stake.lido.fi',
      iconUrl: 'https://stake.lido.fi/favicon.ico',
      description: 'Liquid staking for Ethereum. Stake ETH and receive stETH.',
    ),
    chainId: 'eip155:1',
    chainName: 'Ethereum Mainnet',
    connectedAt: DateTime.now().subtract(const Duration(hours: 12)),
    expiresAt: DateTime.now().add(const Duration(days: 7)),
    status: SessionStatus.active,
    methods: ['eth_sendTransaction', 'personal_sign'],
    events: ['chainChanged', 'accountsChanged'],
    walletAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f5bB12',
  );

  static final List<WalletSession> all = [
    uniswap,
    openSea,
    aave,
    ens,
    lido,
  ];
}
