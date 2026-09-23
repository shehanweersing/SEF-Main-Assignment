import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../theme/app_theme.dart';

/// Authenticated app shell with a glass-themed bottom navigation bar.
///
/// This [ShellRoute] builder wraps every authenticated page, providing
/// the persistent bottom nav and gradient background. Part 2 feature
/// screens will be rendered as `child`.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  /// The routed page injected by [ShellRoute].
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Maps bottom-nav indices to route paths.
  static const _navItems = [
    _NavItem(icon: Icons.flight_takeoff_rounded, label: 'Trips', path: '/trips'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget', path: '/budget'),
    _NavItem(icon: Icons.local_activity_rounded, label: 'Activities', path: '/activities'),
    _NavItem(icon: Icons.shield_rounded, label: 'Risk', path: '/risk'),
    _NavItem(icon: Icons.checklist_rounded, label: 'Readiness', path: '/readiness'),
  ];

  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync tab highlight with the current route.
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _navItems.indexWhere((item) => location.startsWith(item.path));
    if (idx != -1 && idx != _currentIndex) {
      setState(() => _currentIndex = idx);
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,

      // ── Gradient background ──────────────────────────────────────
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Column(
          children: [
            // ── Top bar with title + logout ─────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // App title
                    Text(
                      'TravelWise',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: AppTheme.accent,
                          ),
                    ),
                    const Spacer(),
                    // Logout button
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 22),
                      color: AppTheme.textSecondary,
                      tooltip: 'Log out',
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Page content ────────────────────────────────────────
            Expanded(child: widget.child),
          ],
        ),
      ),

      // ── Glass bottom navigation bar ───────────────────────────────
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final isActive = i == _currentIndex;
                    return _GlassNavButton(
                      icon: item.icon,
                      label: item.label,
                      isActive: isActive,
                      onTap: () => _onTabTapped(i),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── Supporting widgets ──

class _NavItem {
  const _NavItem({required this.icon, required this.label, required this.path});
  final IconData icon;
  final String label;
  final String path;
}

class _GlassNavButton extends StatelessWidget {
  const _GlassNavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accent.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppTheme.accent : AppTheme.textTertiary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.accent : AppTheme.textTertiary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
