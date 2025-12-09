import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/storage_providers.dart';
import '../../data/datasources/settings_local_datasource.dart';
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
  SettingsNotifier(this._dataSource) : super(const SettingsState()) {
    _loadSettings();
  }

  final SettingsLocalDataSource _dataSource;

  /// Load settings from storage
  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _dataSource.loadSettings();
      state = state.copyWith(isLoading: false, settings: settings);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings',
      );
    }
  }

  Future<void> _persist(AppSettings settings) async {
    state = state.copyWith(settings: settings, isLoading: false, error: null);
    try {
      await _dataSource.saveSettings(settings);
    } catch (_) {
      state = state.copyWith(error: 'Failed to save settings');
    }
  }

  /// Update selected network
  Future<void> updateNetwork(NetworkType network) async {
    state = state.copyWith(isLoading: true, error: null);
    await _persist(state.settings.copyWith(selectedNetwork: network));
  }

  /// Toggle biometric authentication
  Future<void> toggleBiometric(bool enabled) async {
    state = state.copyWith(isLoading: true, error: null);
    await _persist(state.settings.copyWith(biometricEnabled: enabled));
  }

  /// Toggle PIN authentication
  Future<void> togglePin(bool enabled) async {
    state = state.copyWith(isLoading: true, error: null);
    await _persist(state.settings.copyWith(pinEnabled: enabled));
  }

  /// Update auto-lock duration
  Future<void> updateAutoLockDuration(AutoLockDuration duration) async {
    state = state.copyWith(isLoading: true, error: null);
    await _persist(state.settings.copyWith(autoLockDuration: duration));
  }

  /// Update display currency
  Future<void> updateCurrency(CurrencyType currency) async {
    state = state.copyWith(isLoading: true, error: null);
    await _persist(state.settings.copyWith(displayCurrency: currency));
  }

  /// Toggle notifications
  Future<void> toggleNotifications(bool enabled) async {
    await _persist(
      state.settings.copyWith(notificationsEnabled: enabled),
    );
  }
}

final settingsLocalDataSourceProvider =
    Provider<SettingsLocalDataSource>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return SettingsLocalDataSourceImpl(storage);
});

/// Settings provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final localDataSource = ref.watch(settingsLocalDataSourceProvider);
  return SettingsNotifier(localDataSource);
});

/// Convenience provider for current network
final currentNetworkProvider = Provider<NetworkType>((ref) {
  return ref.watch(settingsProvider).settings.selectedNetwork;
});

/// Convenience provider for biometric status
final biometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).settings.biometricEnabled;
});
