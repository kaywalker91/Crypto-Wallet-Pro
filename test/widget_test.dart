// Basic Flutter widget test for Crypto Wallet Pro
//
// This test verifies that the app launches correctly

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_wallet_pro/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app with ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CryptoWalletApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 6));

    // Verify the app renders without errors
    expect(find.byType(CryptoWalletApp), findsOneWidget);
  });
}
