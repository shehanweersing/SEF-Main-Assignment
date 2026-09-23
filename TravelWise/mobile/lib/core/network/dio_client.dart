import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key used to persist the JWT in secure storage.
const String kTokenStorageKey = 'auth_token';

/// Secure-storage singleton provider.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// A global [ValueNotifier] that fires when a 401 is received.
///
/// The router listens to this to navigate to `/login`, breaking the
/// circular dependency between dioProvider ↔ goRouterProvider ↔ authProvider.
final unauthorizedNotifier = ValueNotifier<int>(0);

/// Dio singleton provider with auth & error interceptors.
///
/// ### Base URL
/// Read from `.env` → `API_BASE_URL`.
/// Android-emulator users should set this to `http://10.0.2.2:<port>/api`;
/// desktop/web users should use `http://localhost:<port>/api`.
///
/// ### Interceptors
/// - **Request**: attaches `Authorization: Bearer <token>` from secure storage.
/// - **Response**: on 401, clears the stored token and signals via
///   [unauthorizedNotifier]. The router listens to this independently.
///
/// ### Dev SSL (Correction #2)
/// In debug mode, `badCertificateCallback` accepts all certificates so
/// self-signed ASP.NET dev certs do not trigger `HandshakeException`.
final dioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5147/api';
  final storage = ref.read(secureStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    },
  ));

  // ── Correction #2: Accept self-signed certs in debug mode ──────────
  if (!kReleaseMode) {
    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }

  // ── Request interceptor — attach Bearer token ──────────────────────
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: kTokenStorageKey);
      if (token != null && token.isNotEmpty) {
        options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
      handler.next(options);
    },

    // ── Response interceptor — handle 401 globally ───────────────────
    onError: (DioException error, handler) async {
      if (error.response?.statusCode == 401) {
        // Clear stale / revoked token
        await storage.delete(key: kTokenStorageKey);

        // Signal the router to redirect to /login.
        // Using a ValueNotifier breaks the provider cycle.
        unauthorizedNotifier.value++;
      }
      handler.next(error);
    },
  ));

  return dio;
});
