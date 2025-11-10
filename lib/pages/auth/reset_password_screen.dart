import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_state.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_snackbar.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final VoidCallback onBackToSignIn;
  final VoidCallback onResetSuccess;
  
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.onBackToSignIn,
    required this.onResetSuccess,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isResetting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState?.validate() != true) return;
    
    setState(() => _isResetting = true);
    
    try {
      final newPassword = _passwordController.text;
      
      // In a real implementation, we would call the backend API to reset the password
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isResetting = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Password reset successfully!',
            type: SnackbarType.success,
          ),
        );
        
        // Navigate to success screen or sign in
        widget.onResetSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResetting = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Failed to reset password. Please try again.',
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
                  const SizedBox(height: 16),
                  // Header
                  const Text(
                    'Reset your password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a new password for your account.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // New Password Field
                        CustomTextField(
                          controller: _passwordController,
                          label: 'New Password',
                          hintText: 'Enter your new password',
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword 
                                ? Icons.visibility_off 
                                : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            // Check for at least one uppercase, one lowercase, and one digit
                            if (!value.contains(RegExp(r'[A-Z]'))) {
                              return 'Password must contain at least one uppercase letter';
                            }
                            if (!value.contains(RegExp(r'[a-z]'))) {
                              return 'Password must contain at least one lowercase letter';
                            }
                            if (!value.contains(RegExp(r'[0-9]'))) {
                              return 'Password must contain at least one digit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Confirm Password Field
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hintText: 'Confirm your new password',
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword 
                                ? Icons.visibility_off 
                                : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Password requirements
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Password must contain:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildRequirementRow(
                                'At least 8 characters',
                                _passwordController.text.length >= 8,
                              ),
                              _buildRequirementRow(
                                'At least one uppercase letter',
                                _passwordController.text.contains(RegExp(r'[A-Z]')),
                              ),
                              _buildRequirementRow(
                                'At least one lowercase letter',
                                _passwordController.text.contains(RegExp(r'[a-z]')),
                              ),
                              _buildRequirementRow(
                                'At least one digit',
                                _passwordController.text.contains(RegExp(r'[0-9]')),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Reset Password Button
                  CustomButton(
                    text: 'Reset Password',
                    onPressed: _isResetting ? () {} : _handleResetPassword,
                    variant: ButtonVariant.filled,
                    size: ButtonSize.large,
                  ),
                  
                  if (_isResetting)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Back to Sign In Button
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
  
  Widget _buildRequirementRow(String text, bool satisfied) {
    return Row(
      children: [
        Icon(
          satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: satisfied 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(
              satisfied ? 1.0 : 0.7,
            ),
          ),
        ),
      ],
    );
  }
}