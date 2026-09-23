import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/readiness_provider.dart';
import '../../core/providers/trips_provider.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// Readiness screen — document checklist with a circular 0–100% score.
///
/// Fetches `GET api/Readiness?tripId=`. Each document shows type, number,
/// expiry, and verified status. The overall readiness score is computed as
/// the percentage of documents that are both verified AND not expired.
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Trip selector ─────────────────────────────────────
          GlassContainer(
            borderRadius: AppTheme.radiusSm,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: readState.selectedTripId,
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
                    ref
                        .read(readinessProvider.notifier)
                        .fetchDocuments(tripId);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (readState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (readState.errorMessage != null)
            GlassContainer(
              borderRadius: AppTheme.radiusMd,
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(readState.errorMessage!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 13))),
              ]),
            )
          else if (readState.selectedTripId != null) ...[
            // ── Circular score ──────────────────────────────────
            Center(
              child: _CircularScore(score: readState.readinessScore),
            ),
            const SizedBox(height: 24),

            // ── Document checklist ──────────────────────────────
            if (readState.documents.isEmpty)
              const Center(
                child: Text('No documents found for this trip',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
              )
            else
              ...readState.documents.map((d) => _DocumentTile(doc: d)),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text('Select a trip to view readiness',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Circular Score ──

class _CircularScore extends StatelessWidget {
  const _CircularScore({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppTheme.success
        : score >= 50
            ? AppTheme.accentSecondary
            : AppTheme.error;

    return GlassContainer(
      borderRadius: 70,
      width: 140,
      height: 140,
      padding: EdgeInsets.zero,
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
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text('Ready',
                  style: TextStyle(
                      color: AppTheme.textTertiary, fontSize: 11)),
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
    final radius = size.width / 2 - 12;
    const strokeWidth = 6.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
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
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────── Document Tile ──

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.doc});
  final TravelDocument doc;

  @override
  Widget build(BuildContext context) {
    final isOk = doc.isVerified && !doc.isExpired;
    final statusColor = isOk ? AppTheme.success : AppTheme.error;
    final statusIcon =
        isOk ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final statusText = doc.isExpired
        ? 'Expired'
        : doc.isVerified
            ? 'Verified'
            : 'Unverified';

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: AppTheme.radiusSm,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Status icon
          Icon(statusIcon, color: statusColor, size: 22),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.documentType,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(doc.documentNumber,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  'Expires: ${doc.expiryDate.day}/${doc.expiryDate.month}/${doc.expiryDate.year}',
                  style: TextStyle(
                    color: doc.isExpired
                        ? AppTheme.error
                        : AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.4), width: 0.5),
            ),
            child: Text(statusText,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
