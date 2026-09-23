import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/readiness_provider.dart';
import '../../core/providers/trips_provider.dart';
import '../glass/glass_chip.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// Redesigned Readiness Screen featuring a circular 0-100% dial inside
/// an Apple Liquid Glass sphere, and glass checkable list tiles.
class ReadinessScreen extends ConsumerStatefulWidget {
  const ReadinessScreen({super.key});

  @override
  ConsumerState<ReadinessScreen> createState() => _ReadinessScreenState();
}

class _ReadinessScreenState extends ConsumerState<ReadinessScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tripsProvider.notifier).fetchTrips());
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(tripsProvider);
    final readState = ref.watch(readinessProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Trip Readiness',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Document verification & preparation checklist',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // ── Trip selector dropdown ─────────────────────────────
          GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: readState.selectedTripId,
                hint: Row(
                  children: const [
                    Icon(Icons.checklist_rounded, color: AppTheme.accent, size: 20),
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
                    ref.read(readinessProvider.notifier).fetchDocuments(tripId);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (readState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (readState.errorMessage != null)
            GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              borderColor: AppTheme.error.withValues(alpha: 0.4),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(readState.errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
              ]),
            )
          else if (readState.selectedTripId != null) ...[
            // ── Glowing Liquid Glass Sphere Circular Score ──────────
            Center(
              child: _GlowingGlassScoreSphere(score: readState.readinessScore),
            ),
            const SizedBox(height: 28),

            const Text(
              'Required Documents',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // ── Document checklist ──────────────────────────────
            if (readState.documents.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(24),
                  child: const Center(
                    child: Text('No travel documents attached to this trip',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ),
                ),
              )
            else
              ...readState.documents.map((d) => _DocumentTile(doc: d)),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: GlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: const [
                    Icon(Icons.assignment_outlined, size: 48, color: AppTheme.textTertiary),
                    SizedBox(height: 12),
                    Text('Select a trip above to verify travel readiness score',
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

class _GlowingGlassScoreSphere extends StatelessWidget {
  const _GlowingGlassScoreSphere({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppTheme.success
        : score >= 50
            ? AppTheme.accentSecondary
            : AppTheme.error;

    return GlassContainer(
      borderRadius: 90,
      width: 180,
      height: 180,
      borderColor: color.withValues(alpha: 0.4),
      tintColor: color.withValues(alpha: 0.08),
      child: CustomPaint(
        painter: _RingPainter(progress: score / 100, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              GlassChip(
                label: score >= 80 ? 'READY TO FLY' : 'INCOMPLETE',
                accentColor: color,
                isSelected: true,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 8.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.doc});
  final TravelDocument doc;

  @override
  Widget build(BuildContext context) {
    final isOk = doc.isVerified && !doc.isExpired;
    final statusColor = isOk ? AppTheme.success : AppTheme.error;
    final statusIcon = isOk ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final statusText = doc.isExpired
        ? 'Expired'
        : doc.isVerified
            ? 'Verified'
            : 'Unverified';

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      borderColor: statusColor.withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.documentType,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  doc.documentNumber,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Expires: ${doc.expiryDate.day}/${doc.expiryDate.month}/${doc.expiryDate.year}',
                  style: TextStyle(
                    color: doc.isExpired ? AppTheme.error : AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          GlassChip(
            label: statusText,
            accentColor: statusColor,
            isSelected: true,
          ),
        ],
      ),
    );
  }
}
