import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_notifier.dart';
import 'core/router/app_router.dart';
import 'ui/theme/app_theme.dart';

/// TravelWise Mobile — entry point.
///
/// 1. Loads `.env` for `API_BASE_URL`.
/// 2. Wraps the app in [ProviderScope] for Riverpod.
/// 3. Attempts to restore a persisted session before first frame.
/// 4. Applies the Liquid Glass dark theme.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env must be listed in pubspec assets).
  await dotenv.load(fileName: '.env');

  runApp(const ProviderScope(child: TravelWiseApp()));
}

class TravelWiseApp extends ConsumerStatefulWidget {
  const TravelWiseApp({super.key});

  @override
  ConsumerState<TravelWiseApp> createState() => _TravelWiseAppState();
}

class _TravelWiseAppState extends ConsumerState<TravelWiseApp> {
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    // Try to restore a previously-saved JWT from secure storage.
    await ref.read(authProvider.notifier).tryRestoreSession();
    if (mounted) setState(() => _initialised = true);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    // Show a minimal splash while restoring session.
    if (!_initialised) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'TravelWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
