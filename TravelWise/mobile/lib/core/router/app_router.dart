import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_notifier.dart';
import '../../ui/screens/login_screen.dart';
import '../../ui/screens/register_screen.dart';
import '../../ui/shell/app_shell.dart';

/// GoRouter provider with auth-based redirect guard.
///
/// ### Route table
/// ```
/// /login        → LoginScreen
/// /register     → RegisterScreen
/// /             → AppShell (authenticated, bottom-nav)
///   ├ /trips        → placeholder
///   ├ /budget       → placeholder
///   ├ /activities   → placeholder
///   ├ /risk         → placeholder
///   └ /readiness    → placeholder
/// ```
final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch auth state so routes recalculate on login / logout.
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,

    // ── Auth redirect guard ──────────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.isAuthenticated;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Not logged in and trying to reach a protected page → login.
      if (!isLoggedIn && !isOnAuth) return '/login';

      // Logged in but still on auth page → home.
      if (isLoggedIn && isOnAuth) return '/';

      return null; // no redirect
    },

    routes: [
      // ── Public routes ───────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Authenticated shell ─────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, __) => '/trips',
          ),
          GoRoute(
            path: '/trips',
            builder: (context, state) => const _Placeholder(label: 'Trips'),
          ),
          GoRoute(
            path: '/budget',
            builder: (context, state) => const _Placeholder(label: 'Budget'),
          ),
          GoRoute(
            path: '/activities',
            builder: (context, state) =>
                const _Placeholder(label: 'Activities'),
          ),
          GoRoute(
            path: '/risk',
            builder: (context, state) =>
                const _Placeholder(label: 'Risk Assessment'),
          ),
          GoRoute(
            path: '/readiness',
            builder: (context, state) =>
                const _Placeholder(label: 'Readiness'),
          ),
        ],
      ),
    ],
  );
});

// ─────────────────────────────── Placeholder (Part 2 will replace) ──

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              fontWeight: FontWeight.w300,
            ),
      ),
    );
  }
}
