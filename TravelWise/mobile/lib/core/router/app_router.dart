import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_notifier.dart';
import '../network/dio_client.dart';
import '../../ui/screens/login_screen.dart';
import '../../ui/screens/register_screen.dart';
import '../../ui/screens/trips_screen.dart';
import '../../ui/screens/budget_screen.dart';
import '../../ui/screens/activity_screen.dart';
import '../../ui/screens/risk_screen.dart';
import '../../ui/screens/readiness_screen.dart';
import '../../ui/screens/approval_screen.dart';
import '../../ui/shell/app_shell.dart';

/// GoRouter provider with auth-based redirect guard.
///
/// ### Route table
/// ```
/// /login        → LoginScreen
/// /register     → RegisterScreen
/// /             → AppShell (authenticated, bottom-nav)
///   ├ /trips        → TripsScreen
///   ├ /budget       → BudgetScreen
///   ├ /activities   → ActivityScreen
///   ├ /risk         → RiskScreen
///   ├ /readiness    → ReadinessScreen
///   └ /approvals    → ApprovalScreen
/// ```
final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch auth state so routes recalculate on login / logout.
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,

    // Listen to the 401 notifier from the Dio interceptor so the router
    // can redirect without a circular provider dependency.
    refreshListenable: unauthorizedNotifier,

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
            builder: (context, state) => const TripsScreen(),
          ),
          GoRoute(
            path: '/budget',
            builder: (context, state) => const BudgetScreen(),
          ),
          GoRoute(
            path: '/activities',
            builder: (context, state) => const ActivityScreen(),
          ),
          GoRoute(
            path: '/risk',
            builder: (context, state) => const RiskScreen(),
          ),
          GoRoute(
            path: '/readiness',
            builder: (context, state) => const ReadinessScreen(),
          ),
          GoRoute(
            path: '/approvals',
            builder: (context, state) => const ApprovalScreen(),
          ),
        ],
      ),
    ],
  );
});
