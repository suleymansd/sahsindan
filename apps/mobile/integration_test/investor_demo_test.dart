// Uses only the seeded local development backend. Never run against production.
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trustmarket_mobile/core/config/app_env.dart';
import 'package:trustmarket_mobile/core/l10n/strings.dart';
import 'package:trustmarket_mobile/core/network/token_store.dart';
import 'package:trustmarket_mobile/features/listings/presentation/screens/listing_detail_screen.dart';
import 'package:trustmarket_mobile/features/listings/presentation/widgets/listing_row.dart';
import 'package:trustmarket_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Native demo: required fields, rejected login, login and listing detail', (tester) async {
    const endpoint = String.fromEnvironment('API_BASE_URL');
    expect(Uri.parse(endpoint).host, isIn(['localhost', '127.0.0.1', '10.0.2.2']),
        reason: 'This scenario must only use the local seeded backend');
    expect(AppEnv.logNetwork, isFalse, reason: 'Run with LOG_NETWORK=false');
    final store = TokenStore(const FlutterSecureStorage());
    await store.clear();
    addTearDown(store.clear);
    final errorHandler = FlutterError.onError;
    await app.main();
    FlutterError.onError = errorHandler;

    Future<void> waitFor(Finder finder) async {
      final deadline = DateTime.now().add(const Duration(seconds: 25));
      while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(finder, findsWidgets);
      await tester.pump(const Duration(milliseconds: 300));
    }

    final login = find.widgetWithText(FilledButton, S.loginTitle);
    await waitFor(login);
    await tester.ensureVisible(login);
    await tester.tap(login);
    await waitFor(find.byType(TextFormField));
    await tester.ensureVisible(login);
    await tester.tap(login);
    await waitFor(find.text('E-posta gerekli'));
    expect(find.text('Sifre gerekli'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'verified@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Wrong-password-123!');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(login);
    await tester.tap(login);
    await waitFor(find.text('E-posta, şifre veya doğrulama kodunu kontrol edin.'));
    expect(find.byType(TextFormField), findsWidgets);

    // Reopen the input connection after hiding the keyboard for submission.
    // WidgetTester caches focusedEditable even after FocusManager.unfocus().
    await tester.ensureVisible(find.byType(TextFormField).at(1));
    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Test1234!');
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(find.byType(TextFormField).at(1)).controller!.text, 'Test1234!');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(login);
    await tester.tap(login);
    await waitFor(find.text('Ara'));
    await tester.tap(find.text('Ara'));
    await waitFor(find.byType(ListingRow));
    final row = tester.widget<ListingRow>(find.byType(ListingRow).first);
    await tester.ensureVisible(find.text(row.listing.title).first);
    await tester.tap(find.text(row.listing.title).first);
    await waitFor(find.byType(ListingDetailScreen));
    await waitFor(find.text(row.listing.title));
    expect(tester.takeException(), isNull);
  });
}
