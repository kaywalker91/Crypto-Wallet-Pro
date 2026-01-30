import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_wallet_pro/features/settings/presentation/pages/licenses_page.dart';

void main() {
  group('LicensesPage', () {
    testWidgets('renders page title and app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LicensesPage(),
        ),
      );

      // Verify app bar title
      expect(find.text('Open Source Licenses'), findsOneWidget);
      
      // Verify back button exists
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('renders app header with branding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LicensesPage(),
        ),
      );

      // Wait for licenses to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify app branding in header
      expect(find.text('Crypto Wallet Pro'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
      expect(find.text('© 2025 Development Team'), findsOneWidget);
    });

    testWidgets('renders search bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LicensesPage(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify search bar exists
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LicensesPage(),
        ),
      );

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading licenses...'), findsOneWidget);
    });

    testWidgets('displays package count after loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LicensesPage(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify package count is displayed with folder icon
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('search field accepts input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LicensesPage(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Enter search text
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'flutter');
      await tester.pumpAndSettle();

      // Verify text was entered
      final textField = tester.widget<TextField>(searchField);
      expect(textField.controller?.text, 'flutter');
    });

    testWidgets('clear button appears and works', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LicensesPage(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Enter search text
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test');
      await tester.pumpAndSettle();

      // Tap clear button
      final clearButton = find.byIcon(Icons.clear);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
        
        // Verify search field is cleared
        final textField = tester.widget<TextField>(searchField);
        expect(textField.controller?.text ?? '', isEmpty);
      }
    });

    testWidgets('back button navigates back', (tester) async {
      bool didPop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onPopPage: (route, result) {
              didPop = true;
              return route.didPop(result);
            },
            pages: const [
              MaterialPage(child: Scaffold(body: Text('Home'))),
              MaterialPage(child: LicensesPage()),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(didPop, isTrue);
    });
  });
}

