import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/activity_provider.dart';
import '../../core/providers/trips_provider.dart';
import '../glass/glass_chip.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// Redesigned Activity Timeline Screen featuring an Apple Liquid Glass
/// vertical timeline, glowing node indicators, and modal add dialog.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tripsProvider.notifier).fetchTrips());
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(tripsProvider);
    final actState = ref.watch(activitiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Screen Title & Header ──────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            'Activity Timeline',
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
            'Schedule & itinerary breakdown',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // ── Trip selector + add button ────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: actState.selectedTripId,
                      hint: Row(
                        children: const [
                          Icon(Icons.local_activity_rounded, color: AppTheme.accent, size: 20),
                          SizedBox(width: 10),
                          Text('Select a trip', style: TextStyle(color: AppTheme.textTertiary, fontSize: 14)),
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
                          ref.read(activitiesProvider.notifier).fetchActivities(tripId);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: actState.selectedTripId != null
                    ? () => _showAddDialog(context, actState.selectedTripId!)
                    : null,
                child: GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(14),
                  tintColor: AppTheme.accent.withValues(alpha: 0.15),
                  borderColor: AppTheme.accent.withValues(alpha: 0.4),
                  child: Icon(
                    Icons.add_rounded,
                    color: actState.selectedTripId != null ? AppTheme.accent : AppTheme.textTertiary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Timeline List ──────────────────────────────────────────────
        Expanded(
          child: actState.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : actState.errorMessage != null
                  ? Center(child: Text(actState.errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 14)))
                  : actState.activities.isEmpty
                      ? Center(
                          child: GlassContainer(
                            borderRadius: 24,
                            margin: const EdgeInsets.all(32),
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_note_outlined, size: 48, color: AppTheme.textTertiary),
                                const SizedBox(height: 12),
                                Text(
                                  actState.selectedTripId == null
                                      ? 'Select a trip above to view itinerary'
                                      : 'No activities scheduled for this trip',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: actState.activities.length,
                          itemBuilder: (context, index) {
                            final act = actState.activities[index];
                            final isLast = index == actState.activities.length - 1;
                            return _TimelineItem(activity: act, isLast: isLast);
                          },
                        ),
        ),
      ],
    );
  }

  // ── Liquid Glass Add-Activity Dialog ──────────────────────────────────────

  Future<void> _showAddDialog(BuildContext context, int tripId) async {
    final trips = ref.read(tripsProvider).trips;
    final trip = trips.firstWhere((t) => t.id == tripId);

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final interestCtrl = TextEditingController();
    DateTime? startTime;
    DateTime? endTime;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            blurSigma: 28,
            borderRadius: 28,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Activity',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trip bounds: ${_fmtDate(trip.startDate)} — ${_fmtDate(trip.endDate)}',
                    style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  _field(titleCtrl, 'Activity Title *', Icons.title_rounded),
                  const SizedBox(height: 12),
                  _field(descCtrl, 'Description (optional)', Icons.notes_rounded),
                  const SizedBox(height: 12),
                  _field(locationCtrl, 'Location *', Icons.place_rounded),
                  const SizedBox(height: 12),
                  _field(interestCtrl, 'Category (e.g. Nature, Food)', Icons.category_rounded),
                  const SizedBox(height: 16),

                  _DateTimePicker(
                    label: 'Start time *',
                    value: startTime,
                    firstDate: trip.startDate,
                    lastDate: trip.endDate,
                    onPicked: (dt) => setDialogState(() => startTime = dt),
                  ),
                  const SizedBox(height: 12),
                  _DateTimePicker(
                    label: 'End time *',
                    value: endTime,
                    firstDate: trip.startDate,
                    lastDate: trip.endDate,
                    onPicked: (dt) => setDialogState(() => endTime = dt),
                  ),
                  const SizedBox(height: 16),

                  if (dialogError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(dialogError!, style: const TextStyle(color: AppTheme.error, fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty || locationCtrl.text.trim().isEmpty) {
                          setDialogState(() => dialogError = 'Title and location are required.');
                          return;
                        }
                        if (startTime == null || endTime == null) {
                          setDialogState(() => dialogError = 'Select both start and end times.');
                          return;
                        }

                        final err = await ref.read(activitiesProvider.notifier).addActivity(
                              tripId: tripId,
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                              startTime: startTime!,
                              endTime: endTime!,
                              location: locationCtrl.text.trim(),
                              interestType: interestCtrl.text.trim().isEmpty ? null : interestCtrl.text.trim(),
                            );

                        if (err != null) {
                          setDialogState(() => dialogError = err);
                        } else {
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        }
                      },
                      child: const Text('Add to Itinerary', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textTertiary, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onPicked,
  });

  final String label;
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? firstDate,
          firstDate: firstDate.subtract(const Duration(days: 1)),
          lastDate: lastDate.add(const Duration(days: 1)),
          builder: (ctx, child) => Theme(
            data: AppTheme.darkTheme.copyWith(colorScheme: AppTheme.darkTheme.colorScheme),
            child: child!,
          ),
        );
        if (date == null || !context.mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
          builder: (ctx, child) => Theme(
            data: AppTheme.darkTheme,
            child: child!,
          ),
        );
        if (time == null) return;

        onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgSurfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppTheme.accent, size: 18),
            const SizedBox(width: 10),
            Text(
              value != null
                  ? '${value!.day}/${value!.month}/${value!.year}  ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
                  : label,
              style: TextStyle(
                color: value != null ? AppTheme.textPrimary : AppTheme.textTertiary,
                fontSize: 13,
                fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.activity, required this.isLast});
  final Activity activity;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent,
                    boxShadow: [
                      BoxShadow(color: AppTheme.accent.withValues(alpha: 0.6), blurRadius: 10),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.accent.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: GlassContainer(
              margin: const EdgeInsets.only(bottom: 20),
              borderRadius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (activity.interestType != null)
                        GlassChip(
                          label: activity.interestType!,
                          accentColor: AppTheme.accent,
                          isSelected: true,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppTheme.accent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${_fmtTime(activity.startTime)} — ${_fmtTime(activity.endTime)}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppTheme.textTertiary, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (activity.description != null && activity.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      activity.description!,
                      style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
