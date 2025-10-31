import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'component/home_screen.dart';
import 'onboarding/onboarding_pager.dart';
import 'onboarding/onboarding_state.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen<OnboardingModel>(onboardingControllerProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final controller = ref.read(onboardingControllerProvider.notifier);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPager(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      if (!controller.isHydrated) return null;
      final completed = ref.read(onboardingControllerProvider).completed;
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      if (!completed) {
        return goingToOnboarding ? null : '/onboarding';
      }
      if (goingToOnboarding) {
        return '/home';
      }
      return null;
    },
  );
});
