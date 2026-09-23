import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';

/// Matches `BudgetHealthDto` from the backend.
///
/// Fields: `totalBudget`, `totalSpent`, `remainingBudget`,
/// `spendingPercentage`, `healthStatus` ("HEALTHY" / "WARNING" / "CRITICAL").
class BudgetHealth {
  const BudgetHealth({
    required this.totalBudget,
    required this.totalSpent,
    required this.remainingBudget,
    required this.spendingPercentage,
    required this.healthStatus,
  });

  final double totalBudget;
  final double totalSpent;
  final double remainingBudget;
  final double spendingPercentage;
  /// "HEALTHY" (≤80%), "WARNING" (≤100%), "CRITICAL" (>100%)
  final String healthStatus;

  factory BudgetHealth.fromJson(Map<String, dynamic> json) {
    return BudgetHealth(
      totalBudget: (json['totalBudget'] as num).toDouble(),
      totalSpent: (json['totalSpent'] as num).toDouble(),
      remainingBudget: (json['remainingBudget'] as num).toDouble(),
      spendingPercentage: (json['spendingPercentage'] as num).toDouble(),
      healthStatus: json['healthStatus'] as String,
    );
  }
}

/// State for a budget health query.
class BudgetHealthState {
  const BudgetHealthState({
    this.health,
    this.isLoading = false,
    this.errorMessage,
    this.selectedTripId,
  });

  final BudgetHealth? health;
  final bool isLoading;
  final String? errorMessage;
  final int? selectedTripId;

  BudgetHealthState copyWith({
    BudgetHealth? health,
    bool? isLoading,
    String? errorMessage,
    int? selectedTripId,
  }) {
    return BudgetHealthState(
      health: health ?? this.health,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedTripId: selectedTripId ?? this.selectedTripId,
    );
  }
}

/// Notifier that fetches budget health from `GET api/Budgets/{tripId}/health`.
class BudgetHealthNotifier extends StateNotifier<BudgetHealthState> {
  BudgetHealthNotifier(this._dio) : super(const BudgetHealthState());

  final Dio _dio;

  Future<void> fetchHealth(int tripId) async {
    state = state.copyWith(
        isLoading: true, errorMessage: null, selectedTripId: tripId);

    try {
      final response = await _dio.get('/Budgets/$tripId/health');
      final health =
          BudgetHealth.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(health: health, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e.response?.data?.toString() ?? 'Failed to load budget health.',
      );
    }
  }
}

final budgetHealthProvider =
    StateNotifierProvider<BudgetHealthNotifier, BudgetHealthState>((ref) {
  return BudgetHealthNotifier(ref.read(dioProvider));
});
