import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import '../../../../core/constants/env_config.dart';
import '../../../../core/constants/metamask_constants.dart';
import '../../domain/entities/external_wallet_connection.dart';

/// Exception thrown when MetaMask is not installed
class MetaMaskNotInstalledException implements Exception {
  final String message;
  const MetaMaskNotInstalledException([this.message = 'MetaMask is not installed']);

  @override
  String toString() => 'MetaMaskNotInstalledException: $message';
}

/// Exception thrown during MetaMask connection
class MetaMaskConnectionException implements Exception {
  final String message;
  final String? code;

  const MetaMaskConnectionException(this.message, {this.code});

  @override
  String toString() => 'MetaMaskConnectionException: $message (code: $code)';
}

/// Service for connecting to MetaMask via WalletConnect and deep links
class MetaMaskService {
  // ignore: deprecated_member_use
  SignClient? _signClient;
  SessionData? _session;
  // ignore: unused_field
  String? _pendingUri; // For potential future use (e.g., retry logic)

  /// Completer for tracking pending connection
  Completer<ExternalWalletConnection>? _connectionCompleter;

  /// Timer for watchdog session detection
  Timer? _watchdogTimer;

  /// Set of initial session topics (to detect new sessions)
  Set<String>? _initialSessionTopics;

  /// ✅ CONCURRENCY: 세션 처리 중복 방지 플래그
  bool _isProcessingSession = false;

  /// Event streams
  final _connectionController = StreamController<ExternalWalletConnection?>.broadcast();
  final _errorController = StreamController<MetaMaskConnectionException>.broadcast();

  /// Stream of connection state changes
  Stream<ExternalWalletConnection?> get connectionStream => _connectionController.stream;

  /// Stream of errors
  Stream<MetaMaskConnectionException> get errorStream => _errorController.stream;

  /// Check if SignClient is initialized
  bool get isInitialized => _signClient != null;

  /// Check if currently connected
  bool get isConnected => _session != null;

  /// Get current session
  SessionData? get currentSession => _session;

  /// Get connected address
  String? get connectedAddress {
    if (_session == null) return null;
    try {
      final namespace = _session!.namespaces['eip155'];
      if (namespace == null || namespace.accounts.isEmpty) return null;
      final account = namespace.accounts.first;
      final parts = account.split(':');
      return parts.length >= 3 ? parts[2] : null;
    } catch (e) {
      return null;
    }
  }

  /// Get connected chain ID
  int? get connectedChainId {
    if (_session == null) return null;
    try {
      final namespace = _session!.namespaces['eip155'];
      if (namespace == null || namespace.accounts.isEmpty) return null;
      final account = namespace.accounts.first;
      final parts = account.split(':');
      return parts.length >= 2 ? int.tryParse(parts[1]) : null;
    } catch (e) {
      return null;
    }
  }

  /// Initialize the SignClient for dApp mode
  Future<void> initialize() async {
    if (_signClient != null) return;

    final projectId = EnvConfig.walletConnectProjectId;
    if (projectId.isEmpty) {
      debugPrint('WalletConnect Project ID is missing');
      return;
    }

    try {
      // ignore: deprecated_member_use
      _signClient = await SignClient.createInstance(
        projectId: projectId,
        metadata: const PairingMetadata(
          name: 'Crypto Wallet Pro',
          description: 'Connect to dApps with Crypto Wallet Pro',
          url: 'https://etherflow.app',
          icons: ['https://cdn-icons-png.flaticon.com/512/2592/2592236.png'],
          redirect: Redirect(
            native: 'cryptowalletpro://',
            universal: 'https://etherflow.app',
          ),
        ),
      );

      // Subscribe to session events
      _signClient!.onSessionConnect.subscribe(_onSessionConnect);
      _signClient!.onSessionDelete.subscribe(_onSessionDelete);
      _signClient!.onSessionUpdate.subscribe(_onSessionUpdate);

      debugPrint('MetaMask SignClient initialized');
    } catch (e) {
      debugPrint('Failed to initialize MetaMask SignClient: $e');
      rethrow;
    }
  }

  /// Check if MetaMask is installed
  Future<bool> isMetaMaskInstalled() async {
    try {
      final uri = Uri.parse(MetaMaskConstants.deepLinkScheme);
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  /// Open MetaMask with WalletConnect URI using dual-strategy deep linking
  Future<bool> _openWithUri(String wcUri) async {
    try {
      // Strategy 1: Custom scheme (preferred)
      final schemeUrl = MetaMaskConstants.buildDeepLink(wcUri);
      final schemeUri = Uri.parse(schemeUrl);

      if (await canLaunchUrl(schemeUri)) {
        final launched = await launchUrl(
          schemeUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }

      // Strategy 2: Universal link fallback
      final universalUrl = MetaMaskConstants.buildUniversalLink(wcUri);
      final universalUri = Uri.parse(universalUrl);

      final launchedUniversal = await launchUrl(
        universalUri,
        mode: LaunchMode.externalApplication,
      );

      if (launchedUniversal) return true;

      // Both failed - assume not installed
      throw const MetaMaskNotInstalledException();
    } catch (e) {
      if (e is MetaMaskNotInstalledException) rethrow;
      debugPrint('Error opening MetaMask with URI: $e');
      throw MetaMaskNotInstalledException('Failed to open MetaMask: $e');
    }
  }

  /// Connect to MetaMask
  ///
  /// This initiates a WalletConnect session and opens MetaMask for approval.
  /// Returns the connection details on success.
  Future<ExternalWalletConnection> connect({int chainId = 1}) async {
    await initialize();

    if (_signClient == null) {
      throw const MetaMaskConnectionException(
        'SignClient not initialized',
        code: 'NOT_INITIALIZED',
      );
    }

    // Cancel any pending connection
    _cancelPendingConnection();

    try {
      // Store initial session topics for comparison
      _initialSessionTopics = _signClient!.sessions.getAll().map((s) => s.topic).toSet();

      // Create connection completer
      _connectionCompleter = Completer<ExternalWalletConnection>();

      // Create namespace for Ethereum
      final requiredNamespaces = {
        'eip155': RequiredNamespace(
          chains: ['eip155:$chainId'],
          methods: [
            'eth_sendTransaction',
            'eth_signTransaction',
            'eth_sign',
            'personal_sign',
            'eth_signTypedData',
            'eth_signTypedData_v4',
          ],
          events: ['chainChanged', 'accountsChanged'],
        ),
      };

      debugPrint('Creating WalletConnect session for chain: $chainId');

      // Create connect request
      final connectResponse = await _signClient!.connect(
        requiredNamespaces: requiredNamespaces,
      );

      // Get the URI
      final uri = connectResponse.uri?.toString();
      if (uri == null) {
        throw const MetaMaskConnectionException(
          'Failed to generate WalletConnect URI',
          code: 'URI_GENERATION_FAILED',
        );
      }

      _pendingUri = uri;
      debugPrint('WalletConnect URI generated: ${uri.substring(0, 50)}...');

      // Start watchdog timer for session detection
      _startWatchdogTimer();

      // Open MetaMask with the URI
      await _openWithUri(uri);

      // Wait for approval using the session future OR watchdog detection
      // The connectResponse.session completes when session is established
      final sessionFuture = connectResponse.session.future;

      // Race between: session future, watchdog detection, or timeout
      final result = await Future.any<ExternalWalletConnection>([
        sessionFuture.then((session) => _handleSessionEstablished(session)),
        _connectionCompleter!.future,
      ]).timeout(
        MetaMaskConstants.connectionTimeout,
        onTimeout: () {
          throw const MetaMaskConnectionException(
            'Connection timed out waiting for MetaMask approval',
            code: 'TIMEOUT',
          );
        },
      );

      return result;
    } catch (e) {
      _cancelPendingConnection();

      if (e is MetaMaskConnectionException) {
        if (!MetaMaskConstants.expectedFailureCodes.contains(e.code)) {
          _errorController.add(e);
        }
        rethrow;
      }
      if (e is MetaMaskNotInstalledException) rethrow;

      final exception = MetaMaskConnectionException(
        'Failed to connect: $e',
        code: 'CONNECTION_FAILED',
      );
      _errorController.add(exception);
      throw exception;
    }
  }

  /// Handle session established event
  /// ✅ CONCURRENCY: synchronized로 중복 호출 방지
  ExternalWalletConnection _handleSessionEstablished(SessionData session) {
    // Race condition 방지: 이미 처리 중이면 현재 세션 정보 반환
    if (_isProcessingSession) {
      debugPrint('Session already being processed, skipping duplicate');
      return ExternalWalletConnection(
        address: connectedAddress ?? '',
        chainId: connectedChainId ?? 1,
        sessionTopic: _session?.topic ?? session.topic,
        walletName: _session?.peer.metadata.name ?? session.peer.metadata.name,
        connectedAt: DateTime.now(),
      );
    }

    _isProcessingSession = true;
    _session = session;
    _stopWatchdogTimer();

    final connection = ExternalWalletConnection(
      address: connectedAddress ?? '',
      chainId: connectedChainId ?? 1,
      sessionTopic: session.topic,
      walletName: session.peer.metadata.name,
      connectedAt: DateTime.now(),
    );

    _connectionController.add(connection);
    debugPrint('MetaMask connected: ${connection.abbreviatedAddress}');

    // Complete the completer if still pending
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.complete(connection);
    }

    // ✅ CONCURRENCY: 처리 완료 후 플래그 리셋
    _isProcessingSession = false;

    return connection;
  }

  /// Start watchdog timer for session detection
  void _startWatchdogTimer() {
    int attempts = 0;
    _watchdogTimer = Timer.periodic(MetaMaskConstants.watchdogInterval, (timer) {
      attempts++;

      if (_connectionCompleter == null || _connectionCompleter!.isCompleted) {
        timer.cancel();
        return;
      }

      if (attempts > MetaMaskConstants.maxWatchdogAttempts) {
        timer.cancel();
        return;
      }

      // Check for new sessions
      final currentSessions = _signClient?.sessions.getAll() ?? [];
      for (final session in currentSessions) {
        if (_initialSessionTopics?.contains(session.topic) == false) {
          // New session detected
          if (_validateMetaMaskSession(session)) {
            timer.cancel();
            _handleSessionEstablished(session);
            return;
          }
        }
      }
    });
  }

  /// Stop watchdog timer
  void _stopWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  /// Validate that session is from MetaMask
  bool _validateMetaMaskSession(SessionData session) {
    final name = session.peer.metadata.name.toLowerCase();
    return name.contains('metamask');
  }

  /// Cancel pending connection attempt
  void _cancelPendingConnection() {
    _stopWatchdogTimer();
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.completeError(
        const MetaMaskConnectionException('Connection cancelled', code: 'CANCELLED'),
      );
    }
    _connectionCompleter = null;
    _pendingUri = null;
    _initialSessionTopics = null;
    // ✅ CONCURRENCY: 취소 시에도 플래그 리셋
    _isProcessingSession = false;
  }

  /// Disconnect from MetaMask
  Future<void> disconnect() async {
    if (_session == null || _signClient == null) return;

    try {
      await _signClient!.disconnect(
        topic: _session!.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
      );
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    } finally {
      _session = null;
      _connectionController.add(null);
    }
  }

  /// Session connect callback
  void _onSessionConnect(SessionConnect? args) {
    if (args == null) return;
    debugPrint('Session connected: ${args.session.topic}');

    // Only handle if we're waiting for a connection
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      if (_validateMetaMaskSession(args.session)) {
        _handleSessionEstablished(args.session);
      }
    }
  }

  /// Session delete callback
  void _onSessionDelete(SessionDelete? args) {
    if (args == null) return;
    debugPrint('Session deleted: ${args.topic}');

    if (_session?.topic == args.topic) {
      _session = null;
      _connectionController.add(null);
    }
  }

  /// Session update callback
  void _onSessionUpdate(SessionUpdate? args) {
    if (args == null) return;
    debugPrint('Session updated: ${args.topic}');

    // Refresh session data if it's our current session
    if (_session?.topic == args.topic && _signClient != null) {
      final updatedSession = _signClient!.sessions.get(args.topic);
      if (updatedSession != null) {
        _session = updatedSession;
        _connectionController.add(ExternalWalletConnection(
          address: connectedAddress ?? '',
          chainId: connectedChainId ?? 1,
          sessionTopic: updatedSession.topic,
          walletName: updatedSession.peer.metadata.name,
          connectedAt: DateTime.now(),
        ));
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _cancelPendingConnection();
    _connectionController.close();
    _errorController.close();

    _signClient?.onSessionConnect.unsubscribe(_onSessionConnect);
    _signClient?.onSessionDelete.unsubscribe(_onSessionDelete);
    _signClient?.onSessionUpdate.unsubscribe(_onSessionUpdate);
  }
}
