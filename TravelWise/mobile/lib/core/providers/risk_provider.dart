import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';

/// Matches `WeatherTelemetryDto` from the backend.
class WeatherTelemetry {
  const WeatherTelemetry({
    required this.destination,
    required this.source,
    required this.isFallback,
    this.temperatureC,
    this.relativeHumidity,
    this.windSpeedKmh,
    this.weatherCode,
    required this.summary,
    required this.advisory,
    required this.retrievedAtUtc,
  });

  final String destination;
  final String source;
  final bool isFallback;
  final double? temperatureC;
  final double? relativeHumidity;
  final double? windSpeedKmh;
  final int? weatherCode;
  final String summary;
  final String advisory;
  final DateTime retrievedAtUtc;

  factory WeatherTelemetry.fromJson(Map<String, dynamic> json) {
    return WeatherTelemetry(
      destination: json['destination'] as String,
      source: json['source'] as String,
      isFallback: json['isFallback'] as bool,
      temperatureC: (json['temperatureC'] as num?)?.toDouble(),
      relativeHumidity: (json['relativeHumidity'] as num?)?.toDouble(),
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble(),
      weatherCode: json['weatherCode'] as int?,
      summary: json['summary'] as String,
      advisory: json['advisory'] as String,
      retrievedAtUtc: DateTime.parse(json['retrievedAtUtc'] as String),
    );
  }
}

/// Matches backend [RiskAssessment] model.
class RiskAssessment {
  const RiskAssessment({
    required this.id,
    required this.tripId,
    required this.destination,
    required this.severityLevel,
    required this.advisoryMessage,
    required this.assessmentDate,
  });

  final int id;
  final int tripId;
  final String destination;
  /// "Low", "Moderate", "High", "Critical"
  final String severityLevel;
  final String advisoryMessage;
  final DateTime assessmentDate;

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      id: json['id'] as int,
      tripId: json['tripId'] as int,
      destination: json['destination'] as String,
      severityLevel: json['severityLevel'] as String,
      advisoryMessage: json['advisoryMessage'] as String,
      assessmentDate: DateTime.parse(json['assessmentDate'] as String),
    );
  }
}

class RiskState {
  const RiskState({
    this.weather,
    this.assessments = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedTripId,
  });

  final WeatherTelemetry? weather;
  final List<RiskAssessment> assessments;
  final bool isLoading;
  final String? errorMessage;
  final int? selectedTripId;

  RiskState copyWith({
    WeatherTelemetry? weather,
    List<RiskAssessment>? assessments,
    bool? isLoading,
    String? errorMessage,
    int? selectedTripId,
  }) {
    return RiskState(
      weather: weather ?? this.weather,
      assessments: assessments ?? this.assessments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedTripId: selectedTripId ?? this.selectedTripId,
    );
  }
}

class RiskNotifier extends StateNotifier<RiskState> {
  RiskNotifier(this._dio) : super(const RiskState());

  final Dio _dio;

  /// Fetch weather for a destination and risk assessments for a trip.
  Future<void> fetchRiskData(int tripId, String destination) async {
    state = state.copyWith(
        isLoading: true, errorMessage: null, selectedTripId: tripId);
    try {
      final results = await Future.wait([
        _dio.get('/Risk/weather', queryParameters: {'destination': destination}),
        _dio.get('/Risk', queryParameters: {'tripId': tripId}),
      ]);

      final weather =
          WeatherTelemetry.fromJson(results[0].data as Map<String, dynamic>);
      final assessments = (results[1].data as List)
          .map((e) => RiskAssessment.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
          weather: weather, assessments: assessments, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e.response?.data?.toString() ?? 'Failed to load risk data.',
      );
    }
  }
}

final riskProvider =
    StateNotifierProvider<RiskNotifier, RiskState>((ref) {
  return RiskNotifier(ref.read(dioProvider));
});
