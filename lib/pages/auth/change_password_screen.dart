import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_state.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_snackbar.dart';

class ChangePasswordScreen extends StatefulWidget {
  final VoidCallback onPasswordChanged;
  final VoidCallback onBack;
  
  const ChangePasswordScreen({
    super.key,
    required this.onPasswordChanged,
    required this.onBack,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isObscureCurrent = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate inputs
    if (currentPassword.isEmpty) {
      CustomSnackbar.show(
        context,
        CustomSnackbar(
          message: 'Please enter your current password',
          type: SnackbarType.error,
        ),
      );
      return;
    }

    if (newPassword.isEmpty) {
      CustomSnackbar.show(
        context,
        CustomSnackbar(
          message: 'Please enter a new password',
          type: SnackbarType.error,
        ),
      );
      return;
    }

    if (newPassword.length < 8) {
      CustomSnackbar.show(
        context,
        CustomSnackbar(
          message: 'Password must be at least 8 characters',
          type: SnackbarType.error,
        ),
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      CustomSnackbar.show(
        context,
        CustomSnackbar(
          message: 'Please confirm your new password',
          type: SnackbarType.error,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      CustomSnackbar.show(
        context,
        CustomSnackbar(
          message: 'New passwords do not match',
          type: SnackbarType.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthState>();
      
      // Call the backend API to change the password
      await authState.updatePassword(currentPassword, newPassword);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Password changed successfully',
            type: SnackbarType.success,
          ),
        );
        
        // Clear the form
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        // Notify that password has been changed
        widget.onPasswordChanged();
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: e.message,
            type: SnackbarType.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Failed to change password. Please try again.',
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
          onPressed: widget.onBack,
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
                    'Change Password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update your account password',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Current Password
                  CustomTextField(
                    controller: _currentPasswordController,
                    label: 'Current Password',
                    hintText: 'Enter your current password',
                    obscureText: _isObscureCurrent,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscureCurrent ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscureCurrent = !_isObscureCurrent;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // New Password
                  CustomTextField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    hintText: 'Enter your new password',
                    obscureText: _isObscureNew,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscureNew = !_isObscureNew;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Confirm Password
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm New Password',
                    hintText: 'Confirm your new password',
                    obscureText: _isObscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscureConfirm ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscureConfirm = !_isObscureConfirm;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Change Password button
                  CustomButton(
                    text: 'Change Password',
                    onPressed: _isLoading ? () {} : _handleChangePassword,
                    variant: ButtonVariant.filled,
                    size: ButtonSize.large,
                  ),
                  
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator()),
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