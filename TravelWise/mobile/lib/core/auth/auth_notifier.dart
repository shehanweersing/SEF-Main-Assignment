import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../network/dio_client.dart';
import 'auth_state.dart';

/// Riverpod [StateNotifier] that manages authentication lifecycle.
///
/// ### JWT Decode — Correction #3
/// Only `nameid`, `email`, and `role` are decoded from the JWT.
/// `fullName` is **not** in the token — fetch separately if needed.
///
/// ### Endpoints used
/// - `POST /Auth/login`    — `LoginDto { email, password }` → `{ token }`
/// - `POST /Auth/register` — `RegisterDto { fullName, email, password, role }`
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._dio, this._storage) : super(const AuthState());

  final Dio _dio;
  final FlutterSecureStorage _storage;

  // ───────────────────────────────────────────── Initialisation ──

  /// Call once at app start to restore a persisted session.
  Future<void> tryRestoreSession() async {
    final storedToken = await _storage.read(key: kTokenStorageKey);
    if (storedToken == null || storedToken.isEmpty) return;

    // Reject expired tokens immediately.
    if (JwtDecoder.isExpired(storedToken)) {
      await _storage.delete(key: kTokenStorageKey);
      return;
    }

    _applyToken(storedToken);
  }

  // ──────────────────────────────────────────────────── Login ──

  /// Authenticate with `email` and `password`.
  ///
  /// On success, the JWT is persisted to secure storage and the
  /// [AuthState] is updated with decoded claims.
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _dio.post(
        '/Auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String?;
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No token received from server.',
        );
        return;
      }

      await _storage.write(key: kTokenStorageKey, value: token);
      _applyToken(token);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(isLoading: false, errorMessage: message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  // ─────────────────────────────────────────────── Register ──

  /// Create a new account. Does **not** auto-login; call [login] afterwards.
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    UserRole role = UserRole.traveller,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _dio.post(
        '/Auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role.toBackendString(),
        },
      );

      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  // ──────────────────────────────────────────────── Logout ──

  /// Clear persisted token and reset to unauthenticated state.
  Future<void> logout() async {
    await _storage.delete(key: kTokenStorageKey);
    state = AuthState.unauthenticated();
  }

  // ──────────────────────────────────────────── Helpers ──

  /// Decode the JWT and populate [AuthState] with claims.
  ///
  /// **Correction #3**: Only `nameid`, `email`, and `role` are extracted.
  /// `fullName` is NOT in the JWT — do not attempt to decode it.
  void _applyToken(String token) {
    final claims = JwtDecoder.decode(token);

    // ASP.NET serialises standard ClaimTypes into short keys:
    //   ClaimTypes.NameIdentifier → "nameid"
    //   ClaimTypes.Email          → "email"
    //   ClaimTypes.Role           → "role"
    final userIdRaw = claims['nameid'] ??
        claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
    final emailRaw = claims['email'] ??
        claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'];
    final roleRaw = claims['role'] ??
        claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];

    state = AuthState(
      token: token,
      userId: int.tryParse(userIdRaw?.toString() ?? ''),
      email: emailRaw?.toString(),
      role: UserRole.fromString(roleRaw?.toString()),
      isLoading: false,
    );
  }

  /// Extract a human-readable error from a [DioException].
  String _extractErrorMessage(DioException e) {
    if (e.response?.data is String) return e.response!.data as String;
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      return data['message']?.toString() ??
          data['title']?.toString() ??
          'Request failed (${e.response?.statusCode}).';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your network.';
    }
    return e.message ?? 'Request failed.';
  }
}

// ─────────────────────────────────── Riverpod Providers ──

/// Provider for the [AuthNotifier] and its [AuthState].
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.read(dioProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthNotifier(dio, storage);
});
