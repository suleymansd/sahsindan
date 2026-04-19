import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trustmarket_mobile/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('Login form validates required fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            splashFactory: NoSplash.splashFactory,
          ),
          home: LoginScreen(),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Giris Yap'));
    await tester.pump();

    expect(find.text('E-posta gerekli'), findsOneWidget);
    expect(find.text('Sifre gerekli'), findsOneWidget);
  });
}
