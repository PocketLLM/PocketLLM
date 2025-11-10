import 'package:flutter/material.dart';

import 'auth_success_screen.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  final VoidCallback onSignInPressed;
  
  const PasswordResetSuccessScreen({
    super.key,
    required this.onSignInPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AuthSuccessScreen(
      title: 'Password reset successful',
      message: 'Your password has been successfully reset. You can now sign in with your new password.',
      buttonText: 'Sign In',
      onButtonPressed: onSignInPressed,
      icon: Icons.lock_reset,
    );
  }
}