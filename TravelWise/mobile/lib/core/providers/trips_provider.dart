import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';

/// Represents a Trip from `GET api/Trip`.
///
/// Field names match the ASP.NET [Trip] model exactly:
/// `id`, `userId`, `destination`, `startDate`, `endDate`,
/// `travelObjective`, `status`, `createdAt`, `updatedAt`.
class Trip {
  const Trip({
    required this.id,
    required this.userId,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.travelObjective,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String? travelObjective;
  /// Status values: "Created", "Planning", "Awaiting_Approval", "Approved", "Completed"
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int,
      userId: json['userId'] as int,
      destination: json['destination'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      travelObjective: json['travelObjective'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'destination': destination,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'travelObjective': travelObjective,
        'status': status,
      };
}

/// State for the trips list screen.
class TripsState {
  const TripsState({
    this.trips = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  final List<Trip> trips;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  TripsState copyWith({
    List<Trip>? trips,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return TripsState(
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier that fetches trips from `GET api/Trip?search=`.
class TripsNotifier extends StateNotifier<TripsState> {
  TripsNotifier(this._dio) : super(const TripsState());

  final Dio _dio;

  /// Fetch trips, optionally filtered by [search].
  Future<void> fetchTrips({String? search}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, searchQuery: search ?? state.searchQuery);

    try {
      final queryParams = <String, dynamic>{};
      final q = search ?? state.searchQuery;
      if (q.isNotEmpty) queryParams['search'] = q;

      final response = await _dio.get('/Trip', queryParameters: queryParams);
      final list = (response.data as List).map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(trips: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?.toString() ?? 'Failed to load trips.',
      );
    }
  }

  /// Delete a trip via `DELETE api/Trip/{id}`.
  Future<bool> deleteTrip(int id) async {
    try {
      await _dio.delete('/Trip/$id');
      state = state.copyWith(
        trips: state.trips.where((t) => t.id != id).toList(),
      );
      return true;
    } on DioException {
      return false;
    }
  }

  /// Update a trip's status via `PUT api/Trip/{id}`.
  ///
  /// Used by the AI Approval Queue to approve/reject itineraries.
  Future<bool> updateTripStatus(int id, String newStatus) async {
    try {
      final trip = state.trips.firstWhere((t) => t.id == id);
      await _dio.put('/Trip/$id', data: trip.toJson()..['status'] = newStatus);
      await fetchTrips(); // refresh list
      return true;
    } on DioException {
      return false;
    }
  }
}

final tripsProvider = StateNotifierProvider<TripsNotifier, TripsState>((ref) {
  return TripsNotifier(ref.read(dioProvider));
});
