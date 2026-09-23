import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/trips_provider.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// Trips list screen — calls `GET api/Trip?search=`.
///
/// Displays trip results as glass cards with destination, dates, objective,
/// and a colour-coded status chip. Includes a search bar at the top.
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch on first load.
    Future.microtask(() => ref.read(tripsProvider.notifier).fetchTrips());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(tripsProvider.notifier).fetchTrips(search: query);
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(tripsProvider);

    return Column(
      children: [
        // ── Search bar ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: GlassContainer(
            borderRadius: AppTheme.radiusSm,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search trips...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.textTertiary, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppTheme.textTertiary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),

        // ── Content ───────────────────────────────────────────────
        Expanded(
          child: tripsState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent))
              : tripsState.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppTheme.error, size: 40),
                            const SizedBox(height: 12),
                            Text(tripsState.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary)),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => ref
                                  .read(tripsProvider.notifier)
                                  .fetchTrips(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : tripsState.trips.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flight_takeoff_rounded,
                                  size: 56,
                                  color:
                                      AppTheme.accent.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              const Text('No trips found',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 16)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppTheme.accent,
                          onRefresh: () =>
                              ref.read(tripsProvider.notifier).fetchTrips(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: tripsState.trips.length,
                            itemBuilder: (context, index) =>
                                _TripCard(trip: tripsState.trips[index]),
                          ),
                        ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────── Trip Glass Card ──

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: AppTheme.radiusMd,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: destination + status chip
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.destination,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _StatusChip(status: trip.status),
            ],
          ),
          const SizedBox(height: 12),

          // Date range
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: AppTheme.textTertiary, size: 14),
              const SizedBox(width: 6),
              Text(
                '${_formatDate(trip.startDate)} — ${_formatDate(trip.endDate)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          // Travel objective (if present)
          if (trip.travelObjective != null &&
              trip.travelObjective!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_rounded,
                    color: AppTheme.textTertiary, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip.travelObjective!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ─────────────────────────────────── Status Chip ──

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  (Color, String) _resolve(String status) {
    switch (status) {
      case 'Created':
        return (AppTheme.textSecondary, 'Created');
      case 'Planning':
        return (AppTheme.accent, 'Planning');
      case 'Awaiting_Approval':
        return (AppTheme.accentSecondary, 'Awaiting Approval');
      case 'Approved':
        return (AppTheme.success, 'Approved');
      case 'Completed':
        return (const Color(0xFF818CF8), 'Completed');
      default:
        return (AppTheme.textTertiary, status);
    }
  }
}
