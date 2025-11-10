import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_state.dart';
import '../../services/backend_api_service.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBackToSignIn;
  
  const ForgotPasswordScreen({super.key, required this.onBackToSignIn});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _backendApi = BackendApiService();
  
  bool _isSubmitting = false;
  bool _resetEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() != true) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final email = _emailController.text.trim();
      
      // In a real implementation, we would call the backend API to send a password reset email
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 1));
      
      // Show success message
      if (mounted) {
        setState(() {
          _resetEmailSent = true;
          _isSubmitting = false;
        });
        
        // Show snackbar notification
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Password reset email sent to $email',
            type: SnackbarType.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Failed to send password reset email. Please try again.',
            type: SnackbarType.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Header
                  const Text(
                    'Password Reset',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email to receive a password reset code.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  if (_resetEmailSent) ...[
                    // Success state
                    _buildSuccessState(),
                  ] else ...[
                    // Form state
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'Enter your email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email address';
                              }
                              final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'Send Reset Code',
                            onPressed: _isSubmitting ? () {} : _handleSubmit,
                            variant: ButtonVariant.filled,
                            size: ButtonSize.large,
                          ),
                          if (_isSubmitting)
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Back to sign in button
                  Center(
                    child: TextButton(
                      onPressed: widget.onBackToSignIn,
                      child: const Text('Back to Sign In'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSuccessState() {
    return Column(
      children: [
        // Success icon
        Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: theme.colorScheme.primary,
                size: 48,
              ),
            );
          }
        ),
        const SizedBox(height: 24),
        const Text(
          'Email Sent Successfully',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We have sent a password reset code to ${_emailController.text.trim()}. Please check your inbox and follow the instructions to reset your password.',
          style: const TextStyle(
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Open Email App',
          onPressed: () {
            // In a real implementation, this would open the email app
            // For now, we'll just show a snackbar
            CustomSnackbar.show(
              context,
              CustomSnackbar(
                message: 'In a real app, this would open your email app',
                type: SnackbarType.info,
              ),
            );
          },
          variant: ButtonVariant.tonal,
          size: ButtonSize.large,
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Resend Email',
          onPressed: () {
            setState(() {
              _resetEmailSent = false;
            });
          },
          variant: ButtonVariant.text,
          size: ButtonSize.large,
        ),
      ],
    );
  }
}