import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/verification/presentation/screens/verification_status_screen.dart';
import '../../features/verification/presentation/screens/verification_wizard_screen.dart';
import '../../features/listings/presentation/screens/listings_screen.dart';
import '../../features/listings/presentation/screens/listing_detail_screen.dart';
import '../../features/listings/presentation/screens/listing_editor_screen.dart';
import '../../features/listings/presentation/screens/favorites_screen.dart';
import '../../features/listings/presentation/screens/my_listings_screen.dart';
import '../../features/messaging/presentation/screens/threads_screen.dart';
import '../../features/messaging/presentation/screens/thread_detail_screen.dart';
import '../../features/appointments/presentation/screens/appointments_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/listings/presentation/screens/marketplace_home_screen.dart';
import '../../features/listings/presentation/screens/listing_comparison_screen.dart';
import 'main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Keep navigation and form state when auth reports an error or profile update.
  // The refresh stream reevaluates redirects using the current auth state.
  final refresh = GoRouterRefreshStream(ref.watch(_routerRefreshProvider).stream);
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    routes: [
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: '/forgot',
          builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset',
        builder: (context, state) =>
            ResetPasswordScreen(resetToken: state.uri.queryParameters['token']),
      ),
      // Preferred verification routes
      GoRoute(
        path: '/verification/status',
        builder: (context, state) => VerificationStatusScreen(
          gateMessage: state.uri.queryParameters['message'],
          next: state.uri.queryParameters['next'],
        ),
      ),
      GoRoute(
          path: '/verification/verify',
          builder: (context, state) => const VerificationWizardScreen()),
      // Backwards-compatible aliases
      GoRoute(
          path: '/pending/status',
          redirect: (_, state) =>
              '/verification/status${state.uri.hasQuery ? '?${state.uri.query}' : ''}'),
      GoRoute(
          path: '/pending/verify', redirect: (_, __) => '/verification/verify'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            MainShell(navigationShell: navShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/listings',
                builder: (context, state) => const ListingsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const ListingEditorScreen(),
                  ),
                  GoRoute(
                    path: 'favorites',
                    builder: (context, state) => const FavoritesScreen(),
                  ),
                  GoRoute(
                    path: 'mine',
                    builder: (context, state) => const MyListingsScreen(),
                  ),
                  GoRoute(
                      path: 'compare',
                      builder: (context, state) =>
                          const ListingComparisonScreen()),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ListingDetailScreen(
                        id: int.parse(state.pathParameters['id']!)),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => ListingEditorScreen(
                            editListingId:
                                int.parse(state.pathParameters['id']!)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/threads',
                builder: (context, state) => const ThreadsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ThreadDetailScreen(
                        threadId: int.parse(state.pathParameters['id']!)),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/app/appointments',
                  builder: (context, state) => const AppointmentsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/app/profile',
                  builder: (context, state) => const ProfileScreen()),
            ],
          ),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/app/home',
                builder: (context, state) => const MarketplaceHomeScreen())
          ]),
        ],
      ),
    ],
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      if (auth.stage == AuthStage.bootstrapping) {
        return loc == '/splash' ? null : '/splash';
      }

      if (loc == '/splash') {
        return _homeFor(auth.stage);
      }

      final isPublic = loc == '/' ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot' ||
          loc.startsWith('/reset');
      final isVerification =
          loc.startsWith('/verification/') || loc.startsWith('/pending/');
      final isApp = loc.startsWith('/app/');

      if (auth.stage == AuthStage.unauthenticated) {
        return isPublic ? null : '/';
      }

      if (auth.stage == AuthStage.banned) {
        // MVP: banned user is logged out to reduce surface area.
        return loc == '/' ? null : '/';
      }

      // Authenticated (verified or not)
      if (isPublic) {
        return '/app/home';
      }

      // Route-level gating for actions that must be verified (deep-link safety).
      if (_requiresVerification(loc) && !auth.isVerified) {
        final qp = {
          'message': 'Bu islem icin hesabini dogrulaman gerekiyor.',
          'next': loc,
        };
        return Uri(path: '/verification/status', queryParameters: qp)
            .toString();
      }

      if (isVerification) return null;
      return isApp ? null : '/app/home';
    },
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

String _homeFor(AuthStage stage) {
  switch (stage) {
    case AuthStage.unauthenticated:
      return '/';
    case AuthStage.banned:
      return '/';
    case AuthStage.authenticated:
      return '/app/home';
    case AuthStage.bootstrapping:
      return '/splash';
  }
}

bool _requiresVerification(String loc) {
  // Listing creation/editing implies upload/publish, so treat these routes as verified-only.
  if (loc == '/app/listings/new') return true;
  if (loc.startsWith('/app/listings/') && loc.endsWith('/edit')) return true;
  return false;
}

final _routerRefreshProvider = Provider.autoDispose<_RouterRefresh>((ref) {
  final notifier = _RouterRefresh();
  ref.listen(authControllerProvider, (_, __) => notifier.bump());
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _RouterRefresh {
  final _controller = StreamController<void>.broadcast();
  Stream<void> get stream => _controller.stream;

  void bump() {
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<void> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<void> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
