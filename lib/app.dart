import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'motion/tokens.dart';
import 'onboarding/onboarding_state.dart';
import 'router.dart';
import 'services/app_lifecycle_service.dart';
import 'theme/theme.dart';

class PocketApp extends HookConsumerWidget {
  const PocketApp({
    super.key,
    required this.appLifecycleService,
    this.initializationError,
  });

  final AppLifecycleService appLifecycleService;
  final String? initializationError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initializationError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: InitializationErrorScreen(
          appLifecycleService: appLifecycleService,
          message: initializationError!,
        ),
      );
    }

    final onboarding = ref.watch(onboardingFutureProvider);
    return onboarding.when(
      loading: () => MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          backgroundColor: buildAppTheme().scaffoldBackgroundColor,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          backgroundColor: buildAppTheme().scaffoldBackgroundColor,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to load onboarding: $error'),
            ),
          ),
        ),
      ),
      data: (_) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          routerConfig: router,
        ).animate().fadeIn(duration: MotionDurations.medium);
      },
    );
  }
}

class InitializationErrorScreen extends StatelessWidget {
  const InitializationErrorScreen({
    super.key,
    required this.appLifecycleService,
    required this.message,
  });

  final AppLifecycleService appLifecycleService;
  final String message;

  @override
  Widget build(BuildContext context) {
    final summary = appLifecycleService.getInitializationSummary();
    final results = (summary['results'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [];
    final failedServices = results
        .where((result) => result['success'] == false)
        .map((result) => result['service'] as String?)
        .whereType<String>()
        .toList();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PocketLLM ran into an issue while starting up.',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (failedServices.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Services affected:',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...failedServices.map(
                      (service) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                service,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Check your connection or try again shortly, then relaunch the app.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
