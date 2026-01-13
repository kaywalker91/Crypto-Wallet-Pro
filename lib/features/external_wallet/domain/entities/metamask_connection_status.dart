/// Represents the connection status with MetaMask
enum MetaMaskConnectionStatus {
  /// No connection attempt made yet
  disconnected,

  /// Currently attempting to connect
  connecting,

  /// Successfully connected to MetaMask
  connected,

  /// Connection attempt failed
  error,
}

extension MetaMaskConnectionStatusX on MetaMaskConnectionStatus {
  bool get isConnecting => this == MetaMaskConnectionStatus.connecting;
  bool get isConnected => this == MetaMaskConnectionStatus.connected;
  bool get isDisconnected => this == MetaMaskConnectionStatus.disconnected;
  bool get isError => this == MetaMaskConnectionStatus.error;

  String get displayName {
    switch (this) {
      case MetaMaskConnectionStatus.disconnected:
        return 'Disconnected';
      case MetaMaskConnectionStatus.connecting:
        return 'Connecting...';
      case MetaMaskConnectionStatus.connected:
        return 'Connected';
      case MetaMaskConnectionStatus.error:
        return 'Error';
    }
  }
}
