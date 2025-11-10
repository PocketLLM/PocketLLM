import 'package:flutter/material.dart';

import 'auth_success_screen.dart';

class AccountCreatedSuccessScreen extends StatelessWidget {
  final VoidCallback onContinuePressed;
  
  const AccountCreatedSuccessScreen({
    super.key,
    required this.onContinuePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AuthSuccessScreen(
      title: 'Account created',
      message: 'Your PocketLLM account has been successfully created. Let\'s set up your profile.',
      buttonText: 'Continue',
      onButtonPressed: onContinuePressed,
      icon: Icons.person_add,
    );
  }
}