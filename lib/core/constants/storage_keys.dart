/// Keys used for secure storage and local persistence.
class StorageKeys {
  StorageKeys._();

  static const String mnemonic = 'wallet_mnemonic';
  static const String walletAddress = 'wallet_address';
  static const String pin = 'wallet_pin';
  static const String pinSalt = 'wallet_pin_salt';
  static const String wallet = 'wallet_metadata';
  static const String authSessionValidUntil = 'auth_session_valid_until';
  static const String appSettings = 'app_settings';
}
