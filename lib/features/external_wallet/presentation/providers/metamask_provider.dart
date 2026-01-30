import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../data/services/metamask_service.dart';
import '../../domain/entities/external_wallet_connection.dart';
import '../../domain/entities/metamask_connection_status.dart';

part 'metamask_provider.g.dart';

/// State for MetaMask connection
class MetaMaskState {
  final MetaMaskConnectionStatus status;
  final ExternalWalletConnection? connection;
  final String? errorMessage;

  const MetaMaskState({
    this.status = MetaMaskConnectionStatus.disconnected,
    this.connection,
    this.errorMessage,
  });

  MetaMaskState copyWith({
    MetaMaskConnectionStatus? status,
    ExternalWalletConnection? connection,
    String? errorMessage,
  }) {
    return MetaMaskState(
      status: status ?? this.status,
      connection: connection ?? this.connection,
      errorMessage: errorMessage,
    );
  }

  /// Clear error and connection on disconnect
  MetaMaskState disconnected() {
    return const MetaMaskState(
      status: MetaMaskConnectionStatus.disconnected,
      connection: null,
      errorMessage: null,
    );
  }

  @override
  String toString() {
    return 'MetaMaskState(status: $status, connection: $connection, error: $errorMessage)';
  }
}

/// Provider for MetaMaskService singleton
@Riverpod(keepAlive: true)
MetaMaskService metamaskService(Ref ref) {
  final service = MetaMaskService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Provider for MetaMask connection state
@Riverpod(keepAlive: true)
class MetaMaskNotifier extends _$MetaMaskNotifier {
  late final MetaMaskService _service;
  StreamSubscription<ExternalWalletConnection?>? _connectionSubscription;
  StreamSubscription<MetaMaskConnectionException>? _errorSubscription;

  @override
  MetaMaskState build() {
    _service = ref.watch(metamaskServiceProvider);

    // Listen to connection changes
    _connectionSubscription = _service.connectionStream.listen((connection) {
      if (connection != null) {
        state = state.copyWith(
          status: MetaMaskConnectionStatus.connected,
          connection: connection,
          errorMessage: null,
        );
      } else {
        state = state.disconnected();
      }
    });

    // Listen to errors
    _errorSubscription = _service.errorStream.listen((error) {
      if (error.code == 'USER_CANCELLED' || error.code == 'CANCELLED') {
        state = state.disconnected();
      } else {
        state = state.copyWith(
          status: MetaMaskConnectionStatus.error,
          errorMessage: error.message,
        );
      }
    });

    // Cleanup on dispose
    ref.onDispose(() {
      _connectionSubscription?.cancel();
      _errorSubscription?.cancel();
    });

    // Restore session if available
    _restoreSession();

    return const MetaMaskState();
  }

  /// Cancel connection attempt
  void cancelConnect() {
    _service.cancelConnection();
    state = state.disconnected();
  }

  /// Restore existing session on startup
  Future<void> _restoreSession() async {
    try {
      await _service.initialize();

      if (_service.isConnected) {
        final address = _service.connectedAddress;
        final chainId = _service.connectedChainId;
        final session = _service.currentSession;

        if (address != null && session != null) {
          state = state.copyWith(
            status: MetaMaskConnectionStatus.connected,
            connection: ExternalWalletConnection(
              address: address,
              chainId: chainId ?? 1,
              sessionTopic: session.topic,
              walletName: session.peer.metadata.name,
              connectedAt: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error restoring MetaMask session: $e');
    }
  }

  /// Connect to MetaMask
  Future<void> connect({int chainId = 1}) async {
    if (state.status == MetaMaskConnectionStatus.connecting) {
      return; // Already connecting
    }

    state = state.copyWith(
      status: MetaMaskConnectionStatus.connecting,
      errorMessage: null,
    );

    try {
      final connection = await _service.connect(chainId: chainId);
      state = state.copyWith(
        status: MetaMaskConnectionStatus.connected,
        connection: connection,
        errorMessage: null,
      );
    } on MetaMaskNotInstalledException catch (e) {
      state = state.copyWith(
        status: MetaMaskConnectionStatus.error,
        errorMessage: e.message,
      );
    } on MetaMaskConnectionException catch (e) {
      // Handle expected cancellations silently
      if (e.code == 'CANCELLED' || e.code == 'USER_REJECTED') {
        state = state.disconnected();
      } else if (e.code == 'TIMEOUT') {
        state = state.copyWith(
          status: MetaMaskConnectionStatus.error,
          errorMessage: 'Connection timed out. Please try again.',
        );
      } else {
        state = state.copyWith(
          status: MetaMaskConnectionStatus.error,
          errorMessage: e.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: MetaMaskConnectionStatus.error,
        errorMessage: 'Failed to connect: $e',
      );
    }
  }

  /// Disconnect from MetaMask
  Future<void> disconnect() async {
    try {
      await _service.disconnect();
      state = state.disconnected();
    } catch (e) {
      debugPrint('Error disconnecting from MetaMask: $e');
      state = state.disconnected();
    }
  }

  /// Check if MetaMask is installed
  Future<bool> isMetaMaskInstalled() async {
    return await _service.isMetaMaskInstalled();
  }

  /// Clear error state
  void clearError() {
    if (state.status == MetaMaskConnectionStatus.error) {
      state = state.disconnected();
    }
  }
}

/// Convenience provider for connection status
@riverpod
MetaMaskConnectionStatus metamaskConnectionStatus(Ref ref) {
  return ref.watch(metaMaskNotifierProvider).status;
}

/// Convenience provider for connected address
@riverpod
String? metamaskConnectedAddress(Ref ref) {
  return ref.watch(metaMaskNotifierProvider).connection?.address;
}

/// Convenience provider for connection check
@riverpod
bool isMetamaskConnected(Ref ref) {
  return ref.watch(metaMaskNotifierProvider).status == MetaMaskConnectionStatus.connected;
}
