import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/risk_provider.dart';
import '../../core/providers/trips_provider.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// Risk & Weather screen.
///
/// - Fetches `GET api/Risk/weather?destination=` and `GET api/Risk?tripId=`.
/// - If `isFallback == true` on the weather response, shows a clear
///   warning banner instead of treating it as a normal result.
/// - Risk assessments are colour-coded by severity level:
///   Low → teal, Moderate → amber, High → orange, Critical → red.
class RiskScreen extends ConsumerStatefulWidget {
  const RiskScreen({super.key});

  @override
  ConsumerState<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends ConsumerState<RiskScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tripsProvider.notifier).fetchTrips());
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(tripsProvider);
    final riskState = ref.watch(riskProvider);

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
                value: riskState.selectedTripId,
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
                    final trip =
                        tripsState.trips.firstWhere((t) => t.id == tripId);
                    ref
                        .read(riskProvider.notifier)
                        .fetchRiskData(tripId, trip.destination);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Loading / Error ───────────────────────────────────
          if (riskState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (riskState.errorMessage != null)
            GlassContainer(
              borderRadius: AppTheme.radiusMd,
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(riskState.errorMessage!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 13))),
              ]),
            )
          else ...[
            // ── Weather card ──────────────────────────────────
            if (riskState.weather != null) ...[
              // FALLBACK WARNING BANNER
              if (riskState.weather!.isFallback)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSecondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                        color: AppTheme.accentSecondary.withValues(alpha: 0.4),
                        width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppTheme.accentSecondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated data — not real-time',
                              style: TextStyle(
                                  color: AppTheme.accentSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Source: ${riskState.weather!.source}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              _WeatherCard(weather: riskState.weather!),
              const SizedBox(height: 20),
            ],

            // ── Risk assessments ────────────────────────────────
            if (riskState.assessments.isNotEmpty) ...[
              const Text('Risk Assessments',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...riskState.assessments.map((a) => _RiskCard(assessment: a)),
            ],

            if (riskState.selectedTripId == null)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(
                    child: Text('Select a trip to view risk data',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 15))),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────── Weather Card ──

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather});
  final WeatherTelemetry weather;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppTheme.radiusMd,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_rounded, color: AppTheme.accent, size: 22),
              const SizedBox(width: 8),
              Text('Weather — ${weather.destination}',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),

          // Stats grid
          Row(
            children: [
              _WeatherStat(
                  icon: Icons.thermostat_rounded,
                  label: 'Temp',
                  value: weather.temperatureC != null
                      ? '${weather.temperatureC!.toStringAsFixed(1)}°C'
                      : '—'),
              const SizedBox(width: 12),
              _WeatherStat(
                  icon: Icons.water_drop_rounded,
                  label: 'Humidity',
                  value: weather.relativeHumidity != null
                      ? '${weather.relativeHumidity!.toStringAsFixed(0)}%'
                      : '—'),
              const SizedBox(width: 12),
              _WeatherStat(
                  icon: Icons.air_rounded,
                  label: 'Wind',
                  value: weather.windSpeedKmh != null
                      ? '${weather.windSpeedKmh!.toStringAsFixed(0)} km/h'
                      : '—'),
            ],
          ),
          const SizedBox(height: 16),

          Text(weather.summary,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14)),
          if (weather.advisory.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(weather.advisory,
                style: const TextStyle(
                    color: AppTheme.accentSecondary, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  const _WeatherStat(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        borderRadius: AppTheme.radiusSm,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accent, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textTertiary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── Risk Card ──

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.assessment});
  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(assessment.severityLevel);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: AppTheme.radiusSm,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.5), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(assessment.destination,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: color.withValues(alpha: 0.4), width: 0.5),
                ),
                child: Text(assessment.severityLevel,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(assessment.advisoryMessage,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Color _severityColor(String level) {
    switch (level) {
      case 'Low':
        return AppTheme.success;
      case 'Moderate':
        return AppTheme.accentSecondary;
      case 'High':
        return const Color(0xFFFF8C42);
      case 'Critical':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }
}
