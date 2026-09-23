import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/budget_provider.dart';
import '../../core/providers/trips_provider.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// Budget health screen — `GET api/Budgets/{tripId}/health`.
///
/// Shows a glass progress bar and a colour-coded status chip:
/// - **HEALTHY** (≤80%) → teal/green
/// - **WARNING** (≤100%) → amber
/// - **CRITICAL** (>100%) → pink/red
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Trip selector ───────────────────────────────────────
          GlassContainer(
            borderRadius: AppTheme.radiusSm,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: budgetState.selectedTripId,
                hint: const Text('Select a trip',
                    style: TextStyle(color: AppTheme.textTertiary)),
                dropdownColor: AppTheme.bgSurface,
                iconEnabledColor: AppTheme.accent,
                isExpanded: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: tripsState.trips
                    .map((t) => DropdownMenuItem(
                        value: t.id, child: Text(t.destination)))
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

          // ── Budget health card ──────────────────────────────────
          if (budgetState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (budgetState.errorMessage != null)
            _ErrorCard(message: budgetState.errorMessage!)
          else if (budgetState.health != null)
            _BudgetHealthCard(health: budgetState.health!)
          else
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text('Select a trip to view budget health',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Health Card ──

class _BudgetHealthCard extends StatelessWidget {
  const _BudgetHealthCard({required this.health});
  final BudgetHealth health;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(health.healthStatus);
    final pct = health.spendingPercentage / 100;

    return GlassContainer(
      borderRadius: AppTheme.radiusMd,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Icon(_statusIcon(health.healthStatus),
                  color: statusColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Budget Health',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _HealthChip(
                  status: health.healthStatus, color: statusColor),
            ],
          ),
          const SizedBox(height: 24),

          // Glass progress bar
          _GlassProgressBar(value: pct, color: statusColor),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${health.spendingPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _StatTile(
                  label: 'Total Budget',
                  value: health.totalBudget,
                  color: AppTheme.accent),
              const SizedBox(width: 12),
              _StatTile(
                  label: 'Spent',
                  value: health.totalSpent,
                  color: statusColor),
              const SizedBox(width: 12),
              _StatTile(
                  label: 'Remaining',
                  value: health.remainingBudget,
                  color: health.remainingBudget >= 0
                      ? AppTheme.success
                      : AppTheme.error),
            ],
          ),
        ],
      ),
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
        return Icons.check_circle_outline_rounded;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'CRITICAL':
        return Icons.error_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

// ─────────────────────────────── Glass Progress Bar ──

class _GlassProgressBar extends StatelessWidget {
  const _GlassProgressBar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(7),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: math.min(value, 1.0).clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── Health Chip ──

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────── Stat Tile ──

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        borderRadius: AppTheme.radiusSm,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textTertiary, fontSize: 10)),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── Error Card ──

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppTheme.radiusMd,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(color: AppTheme.error, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
