import '../../domain/entities/app_settings.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    required super.selectedNetwork,
    required super.biometricEnabled,
    required super.pinEnabled,
    required super.autoLockDuration,
    required super.displayCurrency,
    required super.notificationsEnabled,
  });

  factory AppSettingsModel.fromEntity(AppSettings settings) {
    return AppSettingsModel(
      selectedNetwork: settings.selectedNetwork,
      biometricEnabled: settings.biometricEnabled,
      pinEnabled: settings.pinEnabled,
      autoLockDuration: settings.autoLockDuration,
      displayCurrency: settings.displayCurrency,
      notificationsEnabled: settings.notificationsEnabled,
    );
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      selectedNetwork: _networkFrom(json['network'] as String?),
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      pinEnabled: json['pinEnabled'] as bool? ?? false,
      autoLockDuration: _autoLockFrom(json['autoLock'] as String?),
      displayCurrency: _currencyFrom(json['currency'] as String?),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'network': selectedNetwork.name,
      'biometricEnabled': biometricEnabled,
      'pinEnabled': pinEnabled,
      'autoLock': autoLockDuration.name,
      'currency': displayCurrency.name,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  static NetworkType _networkFrom(String? value) {
    return NetworkType.values.firstWhere(
      (n) => n.name == value,
      orElse: () => NetworkType.sepolia,
    );
  }

  static AutoLockDuration _autoLockFrom(String? value) {
    return AutoLockDuration.values.firstWhere(
      (d) => d.name == value,
      orElse: () => AutoLockDuration.after5Min,
    );
  }

  static CurrencyType _currencyFrom(String? value) {
    return CurrencyType.values.firstWhere(
      (c) => c.name == value,
      orElse: () => CurrencyType.usd,
    );
  }
}
