import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/trips_provider.dart';
import '../glass/glass_chip.dart';
import '../glass/glass_container.dart';
import '../theme/app_theme.dart';

/// Redesigned **Trips Screen** with Apple Liquid Glass aesthetic,
/// category quick filters, hero destination cards, and search pill.
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'All', 'icon': Icons.explore_rounded},
    {'name': 'Mountains', 'icon': Icons.terrain_rounded},
    {'name': 'Beach', 'icon': Icons.beach_access_rounded},
    {'name': 'Desert', 'icon': Icons.landscape_rounded},
    {'name': 'Cities', 'icon': Icons.location_city_rounded},
  ];

  final List<Map<String, dynamic>> _quickActions = const [
    {'label': 'Hotels', 'icon': Icons.hotel_rounded, 'color': Color(0xFF00D9C0)},
    {'label': 'Ticket', 'icon': Icons.flight_rounded, 'color': Color(0xFFFFC857)},
    {'label': 'Transport', 'icon': Icons.directions_car_rounded, 'color': Color(0xFFFF6B6B)},
    {'label': 'Events', 'icon': Icons.confirmation_number_rounded, 'color': Color(0xFF818CF8)},
  ];

  @override
  void initState() {
    super.initState();
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

  // Pre-selected travel images for destinations
  String _getImageForDestination(String destination) {
    final dest = destination.toLowerCase();
    if (dest.contains('santorini') || dest.contains('greece')) {
      return 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?auto=format&fit=crop&w=800&q=80';
    } else if (dest.contains('beach') || dest.contains('bali') || dest.contains('maldives')) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80';
    } else if (dest.contains('mountain') || dest.contains('swiss') || dest.contains('iceland')) {
      return 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80';
    } else if (dest.contains('japan') || dest.contains('tokyo') || dest.contains('kyoto')) {
      return 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=800&q=80';
    }
    return 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=800&q=80';
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(tripsProvider);

    return CustomScrollView(
      slivers: [
        // ── Top Header & Discover Title ────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Discover',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Explore your upcoming journeys',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                // User Profile & Notification Pills
                Row(
                  children: [
                    GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.notifications_outlined, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.6), width: 1.5),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Search Bar ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearch,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search your trip destination...',
                  hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.accent, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textTertiary, size: 18),
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
        ),

        // ── Category Filter Pills ────────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat['name'] == _selectedCategory;
                return GlassChip(
                  label: cat['name'] as String,
                  icon: cat['icon'] as IconData,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedCategory = cat['name'] as String);
                  },
                );
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Quick Action Categories Circles ─────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _quickActions.map((action) {
                final color = action['color'] as Color;
                return Column(
                  children: [
                    GlassContainer(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(14),
                      tintColor: color.withValues(alpha: 0.12),
                      borderColor: color.withValues(alpha: 0.3),
                      child: Icon(action['icon'] as IconData, color: color, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      action['label'] as String,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── Trips List Content ──────────────────────────────────────
        if (tripsState.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          )
        else if (tripsState.errorMessage != null)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 40),
                    const SizedBox(height: 12),
                    Text(tripsState.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => ref.read(tripsProvider.notifier).fetchTrips(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (tripsState.trips.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flight_takeoff_rounded, size: 64, color: AppTheme.accent.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text('No trips found', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Create a new trip to get started', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final trip = tripsState.trips[index];
                  final imageUrl = _getImageForDestination(trip.destination);
                  return _HeroTripCard(trip: trip, imageUrl: imageUrl);
                },
                childCount: tripsState.trips.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Hero Destination Liquid Glass Card ─────────────────────────────

class _HeroTripCard extends StatelessWidget {
  const _HeroTripCard({required this.trip, required this.imageUrl});
  final Trip trip;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E2640), Color(0xFF0F172A)],
                    ),
                  ),
                ),
              ),
            ),

            // Top Floating Rating & Metric Badges
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const GlassChip(
                    label: '4.9 ★',
                    icon: Icons.star_rounded,
                    accentColor: Color(0xFFFFC857),
                    isSelected: true,
                  ),
                  _StatusGlassChip(status: trip.status),
                ],
              ),
            ),

            // Bottom Liquid Glass Panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GlassContainer(
                borderRadius: 28,
                padding: const EdgeInsets.all(18),
                blurSigma: 24,
                tintColor: Colors.black.withValues(alpha: 0.4),
                borderColor: Colors.white.withValues(alpha: 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.destination,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: AppTheme.accent, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_formatDate(trip.startDate)} — ${_formatDate(trip.endDate)}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Action Pill Button
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // For now, just show a dialog or trigger API
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Intelligent Trip Plan'),
                                    content: const Text('Running AI workflow...'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "Intelligent Plan",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accent.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                "Let's GO!",
                                style: TextStyle(
                                  color: AppTheme.bgPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (trip.travelObjective != null && trip.travelObjective!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        trip.travelObjective!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _StatusGlassChip extends StatelessWidget {
  const _StatusGlassChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _resolve(status);
    return GlassChip(
      label: label,
      accentColor: color,
      isSelected: true,
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
