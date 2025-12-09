import 'dart:async';

import 'package:crypto_wallet_pro/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:crypto_wallet_pro/features/settings/domain/entities/app_settings.dart';
import 'package:crypto_wallet_pro/features/settings/presentation/providers/settings_provider.dart';
import 'package:crypto_wallet_pro/shared/providers/storage_providers.dart';
import 'package:crypto_wallet_pro/shared/services/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemorySecureStorage implements SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    bool isSensitive = true,
  }) async {
    _store[key] = value;
  }
}

void main() {
  Future<void> _waitForLoaded(ProviderContainer container) async {
    await pumpEventQueue();
    await Future.doWhile(() async {
      final state = container.read(settingsProvider);
      if (!state.isLoading) return false;
      await Future.delayed(const Duration(milliseconds: 5));
      return true;
    });
  }

  test('loads persisted settings from storage', () async {
    final storage = InMemorySecureStorage();
    final dataSource = SettingsLocalDataSourceImpl(storage);
    await dataSource.saveSettings(const AppSettings(
      biometricEnabled: true,
      pinEnabled: true,
      selectedNetwork: NetworkType.mainnet,
    ));

    final container = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(storage),
        settingsLocalDataSourceProvider.overrideWithValue(dataSource),
      ],
    );
    addTearDown(container.dispose);

    await _waitForLoaded(container);
    final state = container.read(settingsProvider);

    expect(state.settings.biometricEnabled, isTrue);
    expect(state.settings.selectedNetwork, NetworkType.mainnet);
  });

  test('toggleBiometric persists new value', () async {
    final storage = InMemorySecureStorage();
    final dataSource = SettingsLocalDataSourceImpl(storage);
    final container = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(storage),
        settingsLocalDataSourceProvider.overrideWithValue(dataSource),
      ],
    );
    addTearDown(container.dispose);

    await _waitForLoaded(container);
    await container.read(settingsProvider.notifier).toggleBiometric(true);

    final reloaded = await dataSource.loadSettings();
    expect(reloaded.biometricEnabled, isTrue);
  });
}
