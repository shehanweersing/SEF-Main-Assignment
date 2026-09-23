import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/auth/auth_state.dart';
import '../../core/providers/trips_provider.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// AI Approval Queue — lists trips with status `"Awaiting_Approval"`.
///
/// Approve / Reject controls are:
/// - **Visible and enabled** only when the current user's role is `Admin`.
/// - **Hidden** for `Staff` and `Traveller` users, who see a read-only list
///   with a banner explaining that only admins can approve.
///
/// Uses the real role value `"Admin"` confirmed in Part 1.
class ApprovalScreen extends ConsumerStatefulWidget {
  const ApprovalScreen({super.key});

  @override
  ConsumerState<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends ConsumerState<ApprovalScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tripsProvider.notifier).fetchTrips());
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(tripsProvider);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.role == UserRole.admin;

    final pendingTrips = tripsState.trips
        .where((t) => t.status == 'Awaiting_Approval')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Admin-only banner ────────────────────────────────────
        if (!isAdmin)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentSecondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                    color: AppTheme.accentSecondary.withValues(alpha: 0.3),
                    width: 0.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.accentSecondary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Only Admin users can approve or reject itineraries.',
                      style: TextStyle(
                          color: AppTheme.accentSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        // ── List ────────────────────────────────────────────────
        Expanded(
          child: tripsState.isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.accent))
              : pendingTrips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.approval_rounded,
                              size: 48,
                              color:
                                  AppTheme.accent.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          const Text('No itineraries awaiting approval',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 15)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.accent,
                      onRefresh: () =>
                          ref.read(tripsProvider.notifier).fetchTrips(),
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: pendingTrips.length,
                        itemBuilder: (context, index) =>
                            _ApprovalCard(
                                trip: pendingTrips[index],
                                isAdmin: isAdmin),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────── Approval Card ──

class _ApprovalCard extends ConsumerWidget {
  const _ApprovalCard({required this.trip, required this.isAdmin});
  final Trip trip;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: AppTheme.radiusMd,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.accentSecondary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.destination,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmtDate(trip.startDate)} — ${_fmtDate(trip.endDate)}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.accentSecondary.withValues(alpha: 0.4),
                      width: 0.5),
                ),
                child: const Text('Awaiting',
                    style: TextStyle(
                        color: AppTheme.accentSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),

          if (trip.travelObjective != null &&
              trip.travelObjective!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(trip.travelObjective!,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],

          // ── Admin-only: Approve / Reject buttons ────────────
          if (isAdmin) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await ref
                            .read(tripsProvider.notifier)
                            .updateTripStatus(trip.id, 'Approved');
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Itinerary approved'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.success,
                        side: BorderSide(
                            color: AppTheme.success.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await ref
                            .read(tripsProvider.notifier)
                            .updateTripStatus(trip.id, 'Created');
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Itinerary rejected'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(
                            color: AppTheme.error.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}
