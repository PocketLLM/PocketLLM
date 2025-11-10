import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../services/auth_state.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_snackbar.dart';
import '../../theme/app_colors.dart';

class EmailVerificationPendingScreen extends StatefulWidget {
  final String email;
  final VoidCallback onBackToSignIn;
  
  const EmailVerificationPendingScreen({
    super.key,
    required this.email,
    required this.onBackToSignIn,
  });

  @override
  State<EmailVerificationPendingScreen> createState() => _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState extends State<EmailVerificationPendingScreen> {
  bool _isResending = false;
  int _resendTimer = 30;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        if (_resendTimer <= 0) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResendVerificationEmail() async {
    setState(() => _isResending = true);
    
    try {
      final authState = context.read<AuthState>();
      
      // In a real implementation, we would call the backend API to resend the verification email
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() => _isResending = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Verification email resent to ${widget.email}',
            type: SnackbarType.success,
          ),
        );
        
        // Restart the resend timer
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Failed to resend verification email. Please try again.',
            type: SnackbarType.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: widget.onBackToSignIn,
        ),
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
                  
                  // Email Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColorTokens.brandPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.email,
                        color: AppColorTokens.brandPrimary,
                        size: 48,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  const Text(
                    'Verify your email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    'We\'ve sent a verification email to ${widget.email}. Please check your inbox and click the verification link to activate your account.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Resend section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _resendTimer > 0 
                          ? 'Resend in 0:$_resendTimer' 
                          : 'Didn\'t receive the email?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      if (_resendTimer <= 0) ...[
                        TextButton(
                          onPressed: _isResending ? null : _handleResendVerificationEmail,
                          child: const Text('Resend email'),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Change email button
                  Center(
                    child: TextButton(
                      onPressed: widget.onBackToSignIn,
                      child: const Text('Change email'),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Continue button
                  CustomButton(
                    text: 'I\'ve verified my email',
                    onPressed: widget.onBackToSignIn,
                    variant: ButtonVariant.filled,
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