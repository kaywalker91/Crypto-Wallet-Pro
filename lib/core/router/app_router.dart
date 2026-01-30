import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/main/presentation/pages/main_page.dart';
import '../../features/auth/presentation/pages/lock_screen_page.dart';
import '../../features/wallet/presentation/pages/create_wallet_page.dart';
import '../../features/wallet/presentation/pages/import_wallet_page.dart';
import '../../features/settings/presentation/pages/pin_setup_page.dart';
import '../../features/send/presentation/pages/send_page.dart';
import '../../features/receive/presentation/pages/receive_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/wallet_connect/presentation/pages/qr_scanner_page.dart';
import '../../features/external_wallet/presentation/pages/connect_external_wallet_page.dart';
import '../../features/settings/presentation/pages/licenses_page.dart';
import '../../features/settings/presentation/pages/about_page.dart';

/// Application router configuration
/// Uses GoRouter for declarative routing
class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Onboarding screen
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Main app (with bottom navigation)
      GoRoute(
        path: '/main',
        name: 'main',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Lock screen
      GoRoute(
        path: '/lock',
        name: 'lock',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LockScreenPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Create wallet
      GoRoute(
        path: '/create-wallet',
        name: 'createWallet',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateWalletPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),

      // Import wallet
      GoRoute(
        path: '/import-wallet',
        name: 'importWallet',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ImportWalletPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),

      // PIN setup
      GoRoute(
        path: '/pin-setup',
        name: 'pinSetup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PinSetupPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),

      // Send transaction
      GoRoute(
        path: '/send',
        name: 'send',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SendPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      
      // Receive
      GoRoute(
        path: '/receive',
        name: 'receive',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ReceivePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),

      // History
      GoRoute(
        path: '/history',
        name: 'history',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HistoryPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),

      // QR Scanner
      GoRoute(
        path: '/qr-scanner',
        name: 'qrScanner',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const QrScannerPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Connect External Wallet (MetaMask)
      GoRoute(
        path: '/connect-external-wallet',
        name: 'connectExternalWallet',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConnectExternalWalletPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),

      // Open Source Licenses
      GoRoute(
        path: '/licenses',
        name: 'licenses',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LicensesPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),

      // About page
      GoRoute(
        path: '/about',
        name: 'about',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AboutPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
    ],
  );
}

/// Route names for type-safe navigation
class Routes {
  Routes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String main = '/main';
  static const String lock = '/lock';
  static const String createWallet = '/create-wallet';
  static const String importWallet = '/import-wallet';
  static const String pinSetup = '/pin-setup';
  static const String send = '/send';
  static const String receive = '/receive';
  static const String history = '/history';
  static const String qrScanner = '/qr-scanner';
  static const String connectExternalWallet = '/connect-external-wallet';
  static const String licenses = '/licenses';
  static const String about = '/about';
}
