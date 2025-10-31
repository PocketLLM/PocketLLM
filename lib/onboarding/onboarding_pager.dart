import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../motion/tokens.dart';
import '../theme/colors.dart';
import '../widgets/dot_pager.dart';
import '../widgets/safe_scaffold.dart';
import 'onboarding_state.dart';
import 'screen1_welcome.dart';
import 'screen2_providers.dart';
import 'screen3_routing_tools.dart';
import 'screen4_privacy.dart';
import 'screen5_permissions.dart';
import 'screen6_done.dart';

class OnboardingPager extends HookConsumerWidget {
  const OnboardingPager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = MediaQuery.of(context).accessibilityFeatures.reduceMotion;
    final controller = usePageController();
    final pageValue = useState<double>(0);
    final animationComplete = useState(false);

    useEffect(() {
      void listener() {
        pageValue.value = controller.page ?? controller.initialPage.toDouble();
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    final assets = useMemoized(() {
      return const [
        'assets/illustrations/ob1.png',
        'assets/illustrations/ob2.png',
        'assets/illustrations/ob3.gif',
        'assets/illustrations/ob4.gif',
        'assets/illustrations/ob5.gif',
        'assets/illustrations/ob6.gif',
      ];
    });

    useEffect(() {
      bool cancelled = false;
      Future.microtask(() async {
        for (final asset in assets) {
          if (cancelled) return;
          await precacheImage(AssetImage(asset), context);
        }
        if (!cancelled) {
          animationComplete.value = true;
        }
      });
      return () {
        cancelled = true;
      };
    }, [assets]);

    final state = ref.watch(onboardingControllerProvider);
    final controllerNotifier = ref.read(onboardingControllerProvider.notifier);

    final screens = [
      Screen1Welcome(
        reduceMotion: reduceMotion,
        pageController: controller,
      ),
      Screen2Providers(
        reduceMotion: reduceMotion,
        controller: controller,
        notifier: controllerNotifier,
        state: state,
      ),
      Screen3RoutingTools(
        reduceMotion: reduceMotion,
        controller: controller,
        state: state,
        notifier: controllerNotifier,
      ),
      Screen4Privacy(
        reduceMotion: reduceMotion,
        controller: controller,
        state: state,
        notifier: controllerNotifier,
      ),
      Screen5Permissions(
        reduceMotion: reduceMotion,
        controller: controller,
      ),
      Screen6Done(
        reduceMotion: reduceMotion,
        notifier: controllerNotifier,
      ),
    ];

    useEffect(() {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ));
      return null;
    }, const []);

    return SafeScaffold(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: screens.length,
              physics: const ClampingScrollPhysics(),
              onPageChanged: (index) {
                if (index == screens.length - 1) {
                  controllerNotifier.complete();
                }
              },
              itemBuilder: (context, index) => screens[index],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DotPager(controller: controller, count: screens.length),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: MotionDurations.medium,
                  child: Text(
                    '${(pageValue.value.floor() + 1).clamp(1, screens.length)} / ${screens.length}',
                    key: ValueKey(pageValue.value.floor()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(target: animationComplete.value ? 1 : 0).fadeIn(
          duration: MotionDurations.medium,
        );
  }
}
