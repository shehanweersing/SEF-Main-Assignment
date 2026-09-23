import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';

/// Matches the backend [Activity] model.
class Activity {
  const Activity({
    required this.id,
    required this.tripId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.interestType,
  });

  final int id;
  final int tripId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String? interestType;

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as int,
      tripId: json['tripId'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      location: json['location'] as String,
      interestType: json['interestType'] as String?,
    );
  }
}

class ActivitiesState {
  const ActivitiesState({
    this.activities = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedTripId,
  });

  final List<Activity> activities;
  final bool isLoading;
  final String? errorMessage;
  final int? selectedTripId;

  ActivitiesState copyWith({
    List<Activity>? activities,
    bool? isLoading,
    String? errorMessage,
    int? selectedTripId,
  }) {
    return ActivitiesState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedTripId: selectedTripId ?? this.selectedTripId,
    );
  }
}

/// Notifier for activities. Handles `GET`, `POST` on `api/Activity`.
///
/// The [addActivity] method returns the exact backend error string for
/// 400 (date-bounds) and 409 (time-overlap) responses so the UI can
/// display them verbatim instead of a generic message.
class ActivitiesNotifier extends StateNotifier<ActivitiesState> {
  ActivitiesNotifier(this._dio) : super(const ActivitiesState());

  final Dio _dio;

  Future<void> fetchActivities(int tripId) async {
    state = state.copyWith(
        isLoading: true, errorMessage: null, selectedTripId: tripId);
    try {
      final response =
          await _dio.get('/Activity', queryParameters: {'tripId': tripId});
      final list = (response.data as List)
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(activities: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e.response?.data?.toString() ?? 'Failed to load activities.',
      );
    }
  }

  /// Add a new activity. Returns `null` on success, or the backend's
  /// error string on 400 (bounds) / 409 (overlap).
  Future<String?> addActivity({
    required int tripId,
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    String? interestType,
  }) async {
    try {
      await _dio.post('/Activity', data: {
        'tripId': tripId,
        'title': title,
        'description': description,
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
        'location': location,
        'interestType': interestType,
      });
      // Refresh the list after adding.
      await fetchActivities(tripId);
      return null;
    } on DioException catch (e) {
      // Return the backend's exact 400/409 message.
      if (e.response != null) {
        final data = e.response!.data;
        if (data is String) return data;
        if (data is Map) return data['title']?.toString() ?? data.toString();
      }
      return e.message ?? 'Failed to add activity.';
    }
  }
}

final activitiesProvider =
    StateNotifierProvider<ActivitiesNotifier, ActivitiesState>((ref) {
  return ActivitiesNotifier(ref.read(dioProvider));
});
