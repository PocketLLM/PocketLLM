import 'package:flutter/material.dart';

import '../../widgets/auth/custom_button.dart';

class AuthErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onBack;
  
  const AuthErrorScreen({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        leading: onBack != null
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
                onPressed: onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  
                  // Error icon
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Retry button
                  CustomButton(
                    text: 'Try Again',
                    onPressed: onRetry,
                    variant: ButtonVariant.filled,
                    size: ButtonSize.large,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Back button
                  if (onBack != null)
                    CustomButton(
                      text: 'Go Back',
                      onPressed: onBack!,
                      variant: ButtonVariant.tonal,
                      size: ButtonSize.large,
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