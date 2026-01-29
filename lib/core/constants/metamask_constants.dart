/// MetaMask-specific constants for dApp connection
class MetaMaskConstants {
  MetaMaskConstants._();

  /// MetaMask custom scheme for deep linking
  static const String deepLinkScheme = 'metamask://';

  /// MetaMask Android package name for canLaunchUrl checks
  static const String androidPackage = 'io.metamask';

  /// MetaMask App Store ID for iOS
  static const String appStoreId = '1438144202';

  /// WalletConnect URI parameter format
  static const String wcUriParam = 'wc?uri=';

  /// MetaMask universal link fallback
  static const String universalLinkBase = 'https://metamask.app.link/';

  /// Connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 120);

  /// Watchdog interval for session detection
  static const Duration watchdogInterval = Duration(seconds: 1);

  /// Maximum watchdog attempts before giving up
  static const int maxWatchdogAttempts = 120;

  /// Expected failure codes that should not be logged as errors
  static const Set<String> expectedFailureCodes = {
    'TIMEOUT',
    'USER_REJECTED',
    'USER_CANCELLED',
    'CANCELLED',
  };

  /// Build MetaMask deep link with WalletConnect URI
  static String buildDeepLink(String wcUri) {
    final encodedUri = Uri.encodeComponent(wcUri);
    return '$deepLinkScheme$wcUriParam$encodedUri';
  }

  /// Build MetaMask universal link fallback
  static String buildUniversalLink(String wcUri) {
    final encodedUri = Uri.encodeComponent(wcUri);
    return '$universalLinkBase$wcUriParam$encodedUri';
  }
}
