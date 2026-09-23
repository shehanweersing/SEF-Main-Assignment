import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/risk_provider.dart';
import '../../core/providers/trips_provider.dart';
import '../glass/glass_chip.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// Redesigned Risk & Telemetry Screen with Apple Liquid Glass aesthetic,
/// floating telemetry chips (`2.3 KM`, `17°C`, `4.9 ★`), warning banners
/// for fallback weather data, and severity cards.
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Risk & Weather',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Live destination telemetry & safety advisories',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // ── Trip selector ─────────────────────────────────────
          GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: riskState.selectedTripId,
                hint: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppTheme.accent, size: 20),
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
                    final trip = tripsState.trips.firstWhere((t) => t.id == tripId);
                    ref.read(riskProvider.notifier).fetchRiskData(tripId, trip.destination);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Floating Telemetry Metric Row (Inspired by Sample UI) ────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              GlassChip(label: '2.3 KM', icon: Icons.near_me_rounded, isSelected: false),
              GlassChip(label: '17° C', icon: Icons.wb_sunny_rounded, accentColor: Color(0xFFFFC857), isSelected: true),
              GlassChip(label: '4.9 ★', icon: Icons.star_rounded, accentColor: Color(0xFFFFC857), isSelected: true),
            ],
          ),

          const SizedBox(height: 20),

          // ── Loading / Error ───────────────────────────────────
          if (riskState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (riskState.errorMessage != null)
            GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              borderColor: AppTheme.error.withValues(alpha: 0.4),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(riskState.errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
              ]),
            )
          else ...[
            // ── Weather telemetry card ────────────────────────────────
            if (riskState.weather != null) ...[
              // FALLBACK WARNING BANNER
              if (riskState.weather!.isFallback)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentSecondary.withValues(alpha: 0.5), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.accentSecondary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated Telemetry Banner',
                              style: TextStyle(color: AppTheme.accentSecondary, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Source: ${riskState.weather!.source} (Live telemetry offline)',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              _WeatherCard(weather: riskState.weather!),
              const SizedBox(height: 24),
            ],

            // ── Risk assessments ────────────────────────────────
            if (riskState.assessments.isNotEmpty) ...[
              const Text(
                'Safety & Risk Advisories',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...riskState.assessments.map((a) => _RiskCard(assessment: a)),
            ],

            if (riskState.selectedTripId == null)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: const [
                      Icon(Icons.security_outlined, size: 48, color: AppTheme.textTertiary),
                      SizedBox(height: 12),
                      Text('Select a trip above to load live risk telemetry',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather});
  final WeatherTelemetry weather;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_queue_rounded, color: AppTheme.accent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    weather.destination,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              GlassChip(
                label: weather.temperatureC != null ? '${weather.temperatureC!.toStringAsFixed(1)}°C' : 'Live',
                accentColor: AppTheme.accent,
                isSelected: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Weather stats grid
          Row(
            children: [
              _WeatherStat(
                icon: Icons.thermostat_rounded,
                label: 'Temp',
                value: weather.temperatureC != null ? '${weather.temperatureC!.toStringAsFixed(1)}°C' : '—',
              ),
              const SizedBox(width: 10),
              _WeatherStat(
                icon: Icons.water_drop_rounded,
                label: 'Humidity',
                value: weather.relativeHumidity != null ? '${weather.relativeHumidity!.toStringAsFixed(0)}%' : '—',
              ),
              const SizedBox(width: 10),
              _WeatherStat(
                icon: Icons.air_rounded,
                label: 'Wind',
                value: weather.windSpeedKmh != null ? '${weather.windSpeedKmh!.toStringAsFixed(0)} km/h' : '—',
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text(
            weather.summary,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (weather.advisory.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.accentSecondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weather.advisory,
                      style: const TextStyle(color: AppTheme.accentSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  const _WeatherStat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accent, size: 18),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.assessment});
  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(assessment.severityLevel);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  assessment.destination,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              GlassChip(
                label: assessment.severityLevel,
                accentColor: color,
                isSelected: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            assessment.advisoryMessage,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
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
