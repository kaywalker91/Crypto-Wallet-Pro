import 'package:equatable/equatable.dart';

/// Network type for blockchain connection
enum NetworkType {
  mainnet('Ethereum Mainnet', 1),
  sepolia('Sepolia Testnet', 11155111);

  const NetworkType(this.displayName, this.chainId);
  final String displayName;
  final int chainId;
}

/// Auto-lock duration options
enum AutoLockDuration {
  immediate('Immediately', Duration.zero),
  after1Min('After 1 minute', Duration(minutes: 1)),
  after5Min('After 5 minutes', Duration(minutes: 5)),
  after15Min('After 15 minutes', Duration(minutes: 15)),
  never('Never', Duration(days: 365));

  const AutoLockDuration(this.displayName, this.duration);
  final String displayName;
  final Duration duration;
}

/// Currency display options
enum CurrencyType {
  usd('USD', '\$'),
  eur('EUR', '€'),
  krw('KRW', '₩'),
  gbp('GBP', '£'),
  jpy('JPY', '¥');

  const CurrencyType(this.code, this.symbol);
  final String code;
  final String symbol;
}

/// App settings entity
class AppSettings extends Equatable {
  final NetworkType selectedNetwork;
  final bool biometricEnabled;
  final bool pinEnabled;
  final AutoLockDuration autoLockDuration;
  final CurrencyType displayCurrency;
  final bool notificationsEnabled;

  const AppSettings({
    this.selectedNetwork = NetworkType.sepolia,
    this.biometricEnabled = false,
    this.pinEnabled = false,
    this.autoLockDuration = AutoLockDuration.after5Min,
    this.displayCurrency = CurrencyType.usd,
    this.notificationsEnabled = true,
  });

  AppSettings copyWith({
    NetworkType? selectedNetwork,
    bool? biometricEnabled,
    bool? pinEnabled,
    AutoLockDuration? autoLockDuration,
    CurrencyType? displayCurrency,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      selectedNetwork: selectedNetwork ?? this.selectedNetwork,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
      displayCurrency: displayCurrency ?? this.displayCurrency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [
        selectedNetwork,
        biometricEnabled,
        pinEnabled,
        autoLockDuration,
        displayCurrency,
        notificationsEnabled,
      ];
}
