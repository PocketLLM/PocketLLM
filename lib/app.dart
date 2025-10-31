import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'motion/tokens.dart';
import 'onboarding/onboarding_state.dart';
import 'router.dart';
import 'theme/theme.dart';

class PocketApp extends HookConsumerWidget {
  const PocketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
