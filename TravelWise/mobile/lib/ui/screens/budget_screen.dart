import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/budget_provider.dart';
import '../../core/providers/trips_provider.dart';
import '../glass/glass_chip.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// Budget health screen — `GET api/Budgets/{tripId}/health`.
///
/// Upgraded with Apple Liquid Glass aesthetic, glowing health progress
/// bars, glass currency metrics, and status badges.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tripsProvider.notifier).fetchTrips());
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(tripsProvider);
    final budgetState = ref.watch(budgetHealthProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Budget Health',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitor real-time trip spending & limits',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // ── Trip selector dropdown ─────────────────────────────
          GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: budgetState.selectedTripId,
                hint: Row(
                  children: const [
                    Icon(Icons.flight_takeoff_rounded, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Text('Select a trip destination', style: TextStyle(color: AppTheme.textTertiary, fontSize: 14)),
                  ],
                ),
                dropdownColor: AppTheme.bgSurface,
                iconEnabledColor: AppTheme.accent,
                isExpanded: true,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                items: tripsState.trips
                    .map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.destination),
                        ))
                    .toList(),
                onChanged: (tripId) {
                  if (tripId != null) {
                    ref.read(budgetHealthProvider.notifier).fetchHealth(tripId);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Content ─────────────────────────────────────────────
          if (budgetState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (budgetState.errorMessage != null)
            _ErrorCard(message: budgetState.errorMessage!)
          else if (budgetState.health != null)
            _BudgetHealthCard(health: budgetState.health!)
          else
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: GlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppTheme.textTertiary),
                    SizedBox(height: 12),
                    Text('Select a trip above to view financial health',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Health Card ──────────────────────

class _BudgetHealthCard extends StatelessWidget {
  const _BudgetHealthCard({required this.health});
  final BudgetHealth health;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(health.healthStatus);
    final pct = health.spendingPercentage / 100;

    return Column(
      children: [
        // Main Liquid Glass Progress Card
        GlassContainer(
          borderRadius: 28,
          padding: const EdgeInsets.all(24),
          borderColor: statusColor.withValues(alpha: 0.3),
          tintColor: statusColor.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_statusIcon(health.healthStatus), color: statusColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spending Ratio',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          Text(
                            '${health.spendingPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(color: statusColor, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GlassChip(
                    label: health.healthStatus,
                    accentColor: statusColor,
                    isSelected: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Liquid Glass Progress Bar
              _GlassProgressBar(value: pct, color: statusColor),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Stat Grid Tiles
        Row(
          children: [
            _StatTile(
              label: 'Total Budget',
              value: health.totalBudget,
              color: AppTheme.accent,
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(width: 12),
            _StatTile(
              label: 'Spent',
              value: health.totalSpent,
              color: statusColor,
              icon: Icons.shopping_bag_outlined,
            ),
            const SizedBox(width: 12),
            _StatTile(
              label: 'Remaining',
              value: health.remainingBudget,
              color: health.remainingBudget >= 0 ? AppTheme.success : AppTheme.error,
              icon: Icons.savings_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'HEALTHY':
        return AppTheme.success;
      case 'WARNING':
        return AppTheme.accentSecondary;
      case 'CRITICAL':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'HEALTHY':
        return Icons.check_circle_rounded;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'CRITICAL':
        return Icons.error_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

class _GlassProgressBar extends StatelessWidget {
  const _GlassProgressBar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: math.min(value, 1.0).clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        borderColor: color.withValues(alpha: 0.25),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                '\$${value.toStringAsFixed(0)}',
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      borderColor: AppTheme.error.withValues(alpha: 0.4),
      tintColor: AppTheme.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
