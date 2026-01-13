
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/wallet_connect/data/services/wallet_connect_service.dart';
import '../../features/wallet_connect/presentation/providers/wallet_connect_provider.dart';

part 'deep_link_service.g.dart';

class DeepLinkService {
  final WalletConnectService _walletConnectService;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// Stream controller for MetaMask callback events
  final StreamController<Uri> _metamaskCallbackController = StreamController.broadcast();

  /// Stream of MetaMask callback URIs
  Stream<Uri> get onMetaMaskCallback => _metamaskCallbackController.stream;

  /// Track active subscriptions for cleanup
  final List<StreamSubscription> _activeSubscriptions = [];

  // ✅ SECURITY: URI 검증 상수
  static const int _maxUriLength = 2048;
  static const List<String> _allowedSchemes = ['cryptowalletpro', 'wc', 'https', 'http'];

  DeepLinkService(this._walletConnectService) {
    _init();
  }

  Future<void> _init() async {
    _appLinks = AppLinks();

    // Check for initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Failed to get initial deep link: $e');
    }

    // Listen for new links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');

    // ✅ SECURITY: URI 입력 검증
    if (!_validateUri(uri)) {
      debugPrint('Invalid URI rejected: ${uri.toString().substring(0, uri.toString().length.clamp(0, 50))}...');
      return;
    }

    // Handle MetaMask callback
    // Pattern: cryptowalletpro://metamask/callback or empty callback cryptowalletpro://
    if (uri.scheme == 'cryptowalletpro') {
      if (uri.host == 'metamask' || uri.host.isEmpty || uri.path.isEmpty) {
        // MetaMask callback - user returned from MetaMask app
        debugPrint('MetaMask callback received');
        _metamaskCallbackController.add(uri);

        // If this is just a return callback (no WC URI), exit here
        if (!uri.queryParameters.containsKey('uri')) {
          return;
        }
      }
    }

    // Pattern 1: cryptowalletpro://wc?uri=wc:...
    // Pattern 2: wc:...?symKey=... (If configured to handle wc scheme directly)

    String? wcUri;

    if (uri.scheme == 'wc') {
      wcUri = uri.toString();
    } else if (uri.scheme == 'cryptowalletpro' || uri.scheme == 'https' || uri.scheme == 'http') {
      // Check query parameter 'uri'
      if (uri.queryParameters.containsKey('uri')) {
        wcUri = uri.queryParameters['uri'];
      } else {
        // Sometimes the wc uri is embedded in the path or just as a string?
        // Standard is often custom_scheme://wc?uri=...
        // Or sometimes just passing the whole WC URI as the data.
      }
    }

    if (wcUri != null && wcUri.isNotEmpty) {
      debugPrint('Pairing with WalletConnect URI: $wcUri');
      try {
        // Decode if it's URL-encoded?
        // Usually query parameters are decoded by Uri class, but double check.
        // WalletConnect URIs start with "wc:".

        if (!wcUri.startsWith('wc:')) {
           // It might be double encoded
           wcUri = Uri.decodeComponent(wcUri);
        }

        if (wcUri.startsWith('wc:')) {
           _walletConnectService.pair(wcUri);
        }
      } catch (e) {
        debugPrint('Error pairing via Deep Link: $e');
      }
    }
  }

  /// ✅ SECURITY: URI 입력 검증 메서드
  /// - 길이 제한으로 버퍼 오버플로우 방지
  /// - 허용된 스킴만 처리하여 악의적 URI 차단
  bool _validateUri(Uri uri) {
    try {
      // 길이 검증
      final uriString = uri.toString();
      if (uriString.length > _maxUriLength) {
        debugPrint('URI too long: ${uriString.length} > $_maxUriLength');
        return false;
      }

      // 스킴 검증
      if (!_allowedSchemes.contains(uri.scheme.toLowerCase())) {
        debugPrint('Invalid scheme: ${uri.scheme}');
        return false;
      }

      // 기본 형식 검증
      if (uri.scheme.isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('URI validation error: $e');
      return false;
    }
  }

  /// ✅ MEMORY: Stream 구독 등록 헬퍼
  void addSubscription(StreamSubscription subscription) {
    _activeSubscriptions.add(subscription);
  }

  void dispose() {
    // ✅ MEMORY: 모든 구독 정리
    _linkSubscription?.cancel();
    for (final sub in _activeSubscriptions) {
      sub.cancel();
    }
    _activeSubscriptions.clear();
    _metamaskCallbackController.close();
  }
}

@riverpod
DeepLinkService deepLinkService(DeepLinkServiceRef ref) {
  final walletConnectService = ref.watch(walletConnectServiceProvider);
  final service = DeepLinkService(walletConnectService);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
}
