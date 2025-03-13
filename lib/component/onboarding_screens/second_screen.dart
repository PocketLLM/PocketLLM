import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SecondOnboardingScreen extends StatelessWidget {
  const SecondOnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://assets3.lottiefiles.com/packages/lf20_UJNc2t.json',
            height: 300,
            fit: BoxFit.cover,
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
    );
  }
}