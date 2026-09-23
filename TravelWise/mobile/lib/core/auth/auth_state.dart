import 'package:flutter/foundation.dart';

/// The three role values used by the ASP.NET backend.
///
/// Source: [User.cs] — `"Admin"`, `"Staff"`, `"Traveller"`.
/// - `Admin`     — Full administrative access.
/// - `Staff`     — React web-app users.
/// - `Traveller` — Flutter mobile-app users (default).
enum UserRole {
  admin,
  staff,
  traveller;

  /// Parse a role string from the backend into the enum.
  /// Falls back to [traveller] if the value is unrecognised.
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
        return UserRole.staff;
      case 'traveller':
        return UserRole.traveller;
      default:
        return UserRole.traveller;
    }
  }

  /// The exact string the backend expects (PascalCase).
  String toBackendString() {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.traveller:
        return 'Traveller';
    }
  }
}

/// Immutable authentication state.
///
/// ### Correction #3
/// `fullName` is **not** included in the JWT claims — only
/// `NameIdentifier`, `Email`, and `Role` are present. We therefore
/// intentionally omit `fullName` from the token-decode step.
/// If the app later needs it, a separate API call will fetch it.
@immutable
class AuthState {
  const AuthState({
    this.token,
    this.userId,
    this.email,
    this.role = UserRole.traveller,
    this.isLoading = false,
    this.errorMessage,
  });

  /// JWT bearer token returned by `POST api/Auth/login`.
  final String? token;

  /// Decoded from JWT claim `ClaimTypes.NameIdentifier` (claim key: `nameid`).
  final int? userId;

  /// Decoded from JWT claim `ClaimTypes.Email` (claim key: `email`).
  final String? email;

  /// Decoded from JWT claim `ClaimTypes.Role` (claim key: `role`).
  final UserRole role;

  /// Whether an auth operation (login / register) is in progress.
  final bool isLoading;

  /// Human-readable error from the last failed operation.
  final String? errorMessage;

  /// `true` when a valid token is present.
  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({
    String? token,
    int? userId,
    String? email,
    UserRole? role,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Returns a cleared (logged-out) state.
  factory AuthState.unauthenticated() => const AuthState();

  @override
  String toString() =>
      'AuthState(authenticated=$isAuthenticated, userId=$userId, email=$email, role=$role)';
}
