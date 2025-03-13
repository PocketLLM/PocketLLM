import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ThirdOnboardingScreen extends StatelessWidget {
  const ThirdOnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_ksxv5dud.json',
            height: 300,
            fit: BoxFit.cover,
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
        ],
      ),
    );
  }
}