import 'package:equatable/equatable.dart';

import 'dapp_info.dart';

/// Request type for WalletConnect
enum RequestType {
  sendTransaction,
  signMessage,
  signTypedData,
  signTransaction,
}

/// Session request entity for pending signature/transaction requests
class SessionRequest extends Equatable {
  final String id;
  final String sessionId;
  final DappInfo dapp;
  final String method;
  final RequestType type;
  final Map<String, dynamic> params;
  final DateTime requestedAt;
  final String? chainId;

  const SessionRequest({
    required this.id,
    required this.sessionId,
    required this.dapp,
    required this.method,
    required this.type,
    required this.params,
    required this.requestedAt,
    this.chainId,
  });

  /// Get human-readable request type
  String get typeLabel {
    switch (type) {
      case RequestType.sendTransaction:
        return 'Send Transaction';
      case RequestType.signMessage:
        return 'Sign Message';
      case RequestType.signTypedData:
        return 'Sign Typed Data';
      case RequestType.signTransaction:
        return 'Sign Transaction';
    }
  }

  /// Get icon for request type
  String get typeIcon {
    switch (type) {
      case RequestType.sendTransaction:
        return 'send';
      case RequestType.signMessage:
        return 'signature';
      case RequestType.signTypedData:
        return 'document';
      case RequestType.signTransaction:
        return 'key';
    }
  }

  /// Get formatted time since request
  String get timeSinceRequest {
    final duration = DateTime.now().difference(requestedAt);
    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    }
    return '${duration.inDays}d ago';
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        dapp,
        method,
        type,
        params,
        requestedAt,
        chainId,
      ];
}

/// Mock requests for development and UI testing
class MockRequests {
  MockRequests._();

  static final SessionRequest uniswapSwap = SessionRequest(
    id: 'request_001',
    sessionId: 'session_uniswap_001',
    dapp: const DappInfo(
      name: 'Uniswap',
      url: 'https://app.uniswap.org',
      iconUrl: 'https://app.uniswap.org/favicon.png',
    ),
    method: 'eth_sendTransaction',
    type: RequestType.sendTransaction,
    params: {
      'from': '0x742d35Cc6634C0532925a3b844Bc9e7595f5bB12',
      'to': '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
      'value': '0x0',
      'data': '0x38ed1739...',
      'gas': '0x5208',
      'gasPrice': '0x3b9aca00',
    },
    requestedAt: DateTime.now().subtract(const Duration(minutes: 2)),
    chainId: 'eip155:1',
  );

  static final SessionRequest openSeaSign = SessionRequest(
    id: 'request_002',
    sessionId: 'session_opensea_002',
    dapp: const DappInfo(
      name: 'OpenSea',
      url: 'https://opensea.io',
      iconUrl: 'assets/icons/logo_opensea.png',
    ),
    method: 'personal_sign',
    type: RequestType.signMessage,
    params: {
      'message': 'Welcome to OpenSea!\n\nClick to sign in and accept the OpenSea Terms of Service.',
      'address': '0x742d35Cc6634C0532925a3b844Bc9e7595f5bB12',
    },
    requestedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    chainId: 'eip155:1',
  );

  static final List<SessionRequest> all = [
    uniswapSwap,
    openSeaSign,
  ];
}
