/// File Overview:
/// - Purpose: Second onboarding slide focused on model customization messaging.
/// - Backend Migration: Keep; revise copy once backend-managed model catalog is
///   live.
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SecondOnboardingScreen extends StatelessWidget {
  const SecondOnboardingScreen({Key? key}) : super(key: key);

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
                    Lottie.network(
                      'https://assets3.lottiefiles.com/packages/lf20_UJNc2t.json',
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (context, exception, stackTrace) {
                        return Icon(
                          Icons.settings,
                          size: 300,
                          color: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Customize Your Models',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose from a variety of language models and customize their settings to suit your needs',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
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