import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustmarket_mobile/app.dart';
import 'package:trustmarket_mobile/core/errors/app_error.dart';
import 'package:trustmarket_mobile/core/routing/app_router.dart';
import 'package:trustmarket_mobile/features/auth/presentation/providers/auth_controller.dart';

class DemoAuthController extends AuthController {
  DemoAuthController(super.ref);

  @override
  Future<void> bootstrap() async => setUnauthenticated();

  void rejectLogin() => state = state.copyWith(lastError: const AppError.unauthorized());
  void ban() => state = const AuthState(stage: AuthStage.banned);
}

void main() {
  testWidgets('Auth errors preserve the login route and typed email', (tester) async {
    late DemoAuthController auth;
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith((ref) => auth = DemoAuthController(ref)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const TrustMarketApp()));
    await tester.pumpAndSettle();
    final router = container.read(routerProvider);
    router.go('/login');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'investor@example.test');
    auth.rejectLogin();
    await tester.pumpAndSettle();
    expect(container.read(routerProvider), same(router));
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.text('investor@example.test'), findsOneWidget);

    auth.ban();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
