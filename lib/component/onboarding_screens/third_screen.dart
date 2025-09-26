import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ThirdOnboardingScreen extends StatelessWidget {
  const ThirdOnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 40),
                    Lottie.network(
                      'https://lottie.host/9e8ed740-3dc3-4002-b180-3fe842f94148/vgJGvFoJdw.json',
                      height: MediaQuery.of(context).size.height * 0.4,
                      fit: BoxFit.contain,
                      errorBuilder: (context, exception, stackTrace) {
                        return Icon(
                          Icons.search,
                          size: MediaQuery.of(context).size.height * 0.4,
                          color: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Smart Web Search',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Enhance your conversations with integrated web search capabilities',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}