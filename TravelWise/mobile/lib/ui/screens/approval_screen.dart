import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/auth/auth_state.dart';
import '../../core/providers/trips_provider.dart';
import '../glass/glass_chip.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// AI Approval Queue — lists trips with status `"Awaiting_Approval"`.
///
/// Upgraded with Apple Liquid Glass aesthetic and glowing pill action buttons.
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

    final pendingTrips = tripsState.trips.where((t) => t.status == 'Awaiting_Approval').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            'AI Approval Queue',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Review AI-generated travel itineraries',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // ── Admin-only banner ────────────────────────────────────
        if (!isAdmin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentSecondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentSecondary.withValues(alpha: 0.4), width: 0.8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.accentSecondary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Only Admin users can approve or reject itineraries.',
                      style: TextStyle(color: AppTheme.accentSecondary, fontSize: 12, fontWeight: FontWeight.w600),
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
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : pendingTrips.isEmpty
                  ? Center(
                      child: GlassContainer(
                        borderRadius: 24,
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.approval_rounded, size: 48, color: AppTheme.textTertiary),
                            SizedBox(height: 12),
                            Text('No itineraries currently awaiting approval',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.accent,
                      onRefresh: () => ref.read(tripsProvider.notifier).fetchTrips(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: pendingTrips.length,
                        itemBuilder: (context, index) => _ApprovalCard(trip: pendingTrips[index], isAdmin: isAdmin),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _ApprovalCard extends ConsumerWidget {
  const _ApprovalCard({required this.trip, required this.isAdmin});
  final Trip trip;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentSecondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.destination,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmtDate(trip.startDate)} — ${_fmtDate(trip.endDate)}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const GlassChip(
                label: 'Awaiting',
                accentColor: AppTheme.accentSecondary,
                isSelected: true,
              ),
            ],
          ),

          if (trip.travelObjective != null && trip.travelObjective!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              trip.travelObjective!,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (isAdmin) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await ref.read(tripsProvider.notifier).updateTripStatus(trip.id, 'Approved');
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Itinerary approved successfully'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await ref.read(tripsProvider.notifier).updateTripStatus(trip.id, 'Created');
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Itinerary returned to drafting'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}
