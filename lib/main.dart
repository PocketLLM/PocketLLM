import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/app_lifecycle_service.dart';
import 'services/auth_state.dart';
import 'services/error_service.dart';
import 'services/model_state.dart';
import 'services/pocket_llm_service.dart';
import 'services/theme_service.dart';

Future<void> _initializeCoreServices() async {
  try {
    await PocketLLMService.initializeApiKey();
    await ModelState().init();
  } catch (error, stackTrace) {
    final errorService = ErrorService();
    await errorService.logError(
      'Failed to initialize core services: $error',
      stackTrace,
      type: ErrorType.initialization,
      severity: ErrorSeverity.critical,
    );
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.appLifecycleService,
    this.initializationError,
  });

  final AppLifecycleService appLifecycleService;
  final String? initializationError;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
      ],
      child: ProviderScope(
        child: PocketApp(
          appLifecycleService: appLifecycleService,
          initializationError: initializationError,
        ),
      ),
    );
  }
}

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await ThemeService().init();

    final appLifecycleService = AppLifecycleService();

    try {
      await _initializeCoreServices();

      final initializationSuccess = await appLifecycleService.initializeApp();

      if (initializationSuccess) {
        runApp(MyApp(appLifecycleService: appLifecycleService));
      } else {
        final summary = appLifecycleService.getInitializationSummary();
        final failedServices = (summary['results'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .where((result) => result['success'] == false)
                .map((result) => result['service'] as String?)
                .whereType<String>()
                .join(', ') ??
            'Unknown services';

        runApp(
          MyApp(
            appLifecycleService: appLifecycleService,
            initializationError: 'Failed to initialize services: $failedServices',
          ),
        );
      }
    } catch (error, stackTrace) {
      final errorService = ErrorService();
      await errorService.logError(
        'Critical initialization error: $error',
        stackTrace,
        type: ErrorType.initialization,
        severity: ErrorSeverity.critical,
      );

      runApp(
        MyApp(
          appLifecycleService: appLifecycleService,
          initializationError: error.toString(),
        ),
      );
    }
  }, (error, stackTrace) async {
    final errorService = ErrorService();
    await errorService.logError(
      'Uncaught async error: $error',
      stackTrace,
      type: ErrorType.unknown,
      severity: ErrorSeverity.high,
    );
  });
}
