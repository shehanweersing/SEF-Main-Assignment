import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';

/// Matches backend [TravelDocument] model.
class TravelDocument {
  const TravelDocument({
    required this.id,
    required this.tripId,
    required this.documentType,
    required this.documentNumber,
    required this.expiryDate,
    required this.isVerified,
  });

  final int id;
  final int tripId;
  final String documentType;
  final String documentNumber;
  final DateTime expiryDate;
  final bool isVerified;

  factory TravelDocument.fromJson(Map<String, dynamic> json) {
    return TravelDocument(
      id: json['id'] as int,
      tripId: json['tripId'] as int,
      documentType: json['documentType'] as String,
      documentNumber: json['documentNumber'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      isVerified: json['isVerified'] as bool,
    );
  }

  /// Whether the document has expired.
  bool get isExpired => expiryDate.isBefore(DateTime.now());
}

class ReadinessState {
  const ReadinessState({
    this.documents = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedTripId,
  });

  final List<TravelDocument> documents;
  final bool isLoading;
  final String? errorMessage;
  final int? selectedTripId;

  /// Readiness score: percentage of verified, non-expired docs.
  int get readinessScore {
    if (documents.isEmpty) return 0;
    final valid =
        documents.where((d) => d.isVerified && !d.isExpired).length;
    return ((valid / documents.length) * 100).round();
  }

  ReadinessState copyWith({
    List<TravelDocument>? documents,
    bool? isLoading,
    String? errorMessage,
    int? selectedTripId,
  }) {
    return ReadinessState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedTripId: selectedTripId ?? this.selectedTripId,
    );
  }
}

class ReadinessNotifier extends StateNotifier<ReadinessState> {
  ReadinessNotifier(this._dio) : super(const ReadinessState());

  final Dio _dio;

  Future<void> fetchDocuments(int tripId) async {
    state = state.copyWith(
        isLoading: true, errorMessage: null, selectedTripId: tripId);
    try {
      final response =
          await _dio.get('/Readiness', queryParameters: {'tripId': tripId});
      final list = (response.data as List)
          .map((e) => TravelDocument.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(documents: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e.response?.data?.toString() ?? 'Failed to load documents.',
      );
    }
  }
}

final readinessProvider =
    StateNotifierProvider<ReadinessNotifier, ReadinessState>((ref) {
  return ReadinessNotifier(ref.read(dioProvider));
});
