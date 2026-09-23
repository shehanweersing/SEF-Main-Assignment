import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/activity_provider.dart';
import '../../core/providers/trips_provider.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// Activity timeline screen — `GET api/Activity?tripId=`.
///
/// Includes a glass add-activity dialog that enforces trip date bounds
/// and catches + displays 400 (bounds) and 409 (overlap) errors from
/// the backend verbatim.
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
      children: [
        // ── Trip selector + add button ────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: GlassContainer(
                  borderRadius: AppTheme.radiusSm,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: actState.selectedTripId,
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
                              .read(activitiesProvider.notifier)
                              .fetchActivities(tripId);
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
                  borderRadius: AppTheme.radiusSm,
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.add_rounded,
                      color: actState.selectedTripId != null
                          ? AppTheme.accent
                          : AppTheme.textTertiary,
                      size: 22),
                ),
              ),
            ],
          ),
        ),

        // ── Timeline ──────────────────────────────────────────────
        Expanded(
          child: actState.isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.accent))
              : actState.errorMessage != null
                  ? Center(
                      child: Text(actState.errorMessage!,
                          style: const TextStyle(
                              color: AppTheme.error, fontSize: 14)))
                  : actState.activities.isEmpty
                      ? Center(
                          child: Text(
                            actState.selectedTripId == null
                                ? 'Select a trip to view activities'
                                : 'No activities scheduled',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: actState.activities.length,
                          itemBuilder: (context, index) {
                            final act = actState.activities[index];
                            final isLast =
                                index == actState.activities.length - 1;
                            return _TimelineItem(
                                activity: act, isLast: isLast);
                          },
                        ),
        ),
      ],
    );
  }

  // ── Add-activity dialog ──────────────────────────────────────

  Future<void> _showAddDialog(BuildContext context, int tripId) async {
    // Find the trip to get date bounds.
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
            borderRadius: AppTheme.radiusMd,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Add Activity',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    'Trip dates: ${_fmtDate(trip.startDate)} — ${_fmtDate(trip.endDate)}',
                    style: const TextStyle(
                        color: AppTheme.textTertiary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  _field(titleCtrl, 'Title *'),
                  const SizedBox(height: 12),
                  _field(descCtrl, 'Description'),
                  const SizedBox(height: 12),
                  _field(locationCtrl, 'Location *'),
                  const SizedBox(height: 12),
                  _field(interestCtrl, 'Interest type (e.g. Nature)'),
                  const SizedBox(height: 16),

                  // Date-time pickers
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

                  // Error (backend's exact 400/409 message)
                  if (dialogError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(dialogError!,
                          style: const TextStyle(
                              color: AppTheme.error, fontSize: 12)),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Submit
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Client-side validation
                        if (titleCtrl.text.trim().isEmpty ||
                            locationCtrl.text.trim().isEmpty) {
                          setDialogState(() =>
                              dialogError = 'Title and location are required.');
                          return;
                        }
                        if (startTime == null || endTime == null) {
                          setDialogState(() =>
                              dialogError = 'Select both start and end times.');
                          return;
                        }

                        final err = await ref
                            .read(activitiesProvider.notifier)
                            .addActivity(
                              tripId: tripId,
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim().isEmpty
                                  ? null
                                  : descCtrl.text.trim(),
                              startTime: startTime!,
                              endTime: endTime!,
                              location: locationCtrl.text.trim(),
                              interestType: interestCtrl.text.trim().isEmpty
                                  ? null
                                  : interestCtrl.text.trim(),
                            );

                        if (err != null) {
                          // Show the backend's exact error (400/409).
                          setDialogState(() => dialogError = err);
                        } else {
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        }
                      },
                      child: const Text('Add'),
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

  Widget _field(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

// ─────────────────────────────── Date-Time Picker ──

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
            data: AppTheme.darkTheme.copyWith(
              colorScheme: AppTheme.darkTheme.colorScheme,
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgSurfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                color: AppTheme.textTertiary, size: 16),
            const SizedBox(width: 8),
            Text(
              value != null
                  ? '${value!.day}/${value!.month}/${value!.year}  ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
                  : label,
              style: TextStyle(
                color: value != null
                    ? AppTheme.textPrimary
                    : AppTheme.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── Timeline Item ──

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
          // Timeline gutter
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent,
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.4),
                          blurRadius: 6),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: AppTheme.accent.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Card
          Expanded(
            child: GlassContainer(
              margin: const EdgeInsets.only(bottom: 16),
              borderRadius: AppTheme.radiusSm,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppTheme.textTertiary, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${_fmtTime(activity.startTime)} — ${_fmtTime(activity.endTime)}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppTheme.textTertiary, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(activity.location,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if (activity.interestType != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(activity.interestType!,
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                  if (activity.description != null &&
                      activity.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(activity.description!,
                        style: const TextStyle(
                            color: AppTheme.textTertiary, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
