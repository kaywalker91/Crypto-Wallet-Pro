import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';

/// Settings state for the app
class SettingsState {
  final AppSettings settings;
  final bool isLoading;
  final String? error;

  const SettingsState({
    this.settings = const AppSettings(),
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Settings notifier for managing app settings
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  /// Load settings from storage (Mock)
  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock: Return default settings
    state = state.copyWith(
      isLoading: false,
      settings: const AppSettings(
        selectedNetwork: NetworkType.sepolia,
        biometricEnabled: false,
        pinEnabled: true,
        autoLockDuration: AutoLockDuration.after5Min,
        displayCurrency: CurrencyType.usd,
        notificationsEnabled: true,
      ),
    );
  }

  /// Update selected network
  Future<void> updateNetwork(NetworkType network) async {
    state = state.copyWith(isLoading: true);

    // Simulate save delay
    await Future.delayed(const Duration(milliseconds: 300));

    state = state.copyWith(
      isLoading: false,
      settings: state.settings.copyWith(selectedNetwork: network),
    );
  }

  /// Toggle biometric authentication
  Future<void> toggleBiometric(bool enabled) async {
    state = state.copyWith(isLoading: true);

    // Simulate biometric setup delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock: Always succeed
    state = state.copyWith(
      isLoading: false,
      settings: state.settings.copyWith(biometricEnabled: enabled),
    );
  }

  /// Toggle PIN authentication
  Future<void> togglePin(bool enabled) async {
    state = state.copyWith(isLoading: true);

    await Future.delayed(const Duration(milliseconds: 300));

    state = state.copyWith(
      isLoading: false,
      settings: state.settings.copyWith(pinEnabled: enabled),
    );
  }

  /// Update auto-lock duration
  Future<void> updateAutoLockDuration(AutoLockDuration duration) async {
    state = state.copyWith(isLoading: true);

    await Future.delayed(const Duration(milliseconds: 300));

    state = state.copyWith(
      isLoading: false,
      settings: state.settings.copyWith(autoLockDuration: duration),
    );
  }

  /// Update display currency
  Future<void> updateCurrency(CurrencyType currency) async {
    state = state.copyWith(isLoading: true);

    await Future.delayed(const Duration(milliseconds: 300));

    state = state.copyWith(
      isLoading: false,
      settings: state.settings.copyWith(displayCurrency: currency),
    );
  }

  /// Toggle notifications
  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(
      settings: state.settings.copyWith(notificationsEnabled: enabled),
    );
  }
}

/// Settings provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Convenience provider for current network
final currentNetworkProvider = Provider<NetworkType>((ref) {
  return ref.watch(settingsProvider).settings.selectedNetwork;
});

/// Convenience provider for biometric status
final biometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).settings.biometricEnabled;
});
