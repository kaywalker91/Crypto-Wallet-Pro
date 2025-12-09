import 'dart:convert';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../models/app_settings_model.dart';
import '../../../../shared/services/secure_storage_service.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl(this._storage);

  final SecureStorageService _storage;

  @override
  Future<AppSettings> loadSettings() async {
    try {
      final raw = await _storage.read(StorageKeys.appSettings);
      if (raw == null) {
        return const AppSettings();
      }
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettingsModel.fromJson(map);
    } catch (e) {
      throw StorageFailure('Failed to load settings', cause: e);
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final model = AppSettingsModel.fromEntity(settings);
      await _storage.write(
        key: StorageKeys.appSettings,
        value: jsonEncode(model.toJson()),
        isSensitive: false,
      );
    } catch (e) {
      throw StorageFailure('Failed to save settings', cause: e);
    }
  }
}
