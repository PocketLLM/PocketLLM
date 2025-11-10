import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_state.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_snackbar.dart';
import '../../widgets/auth/custom_checkbox.dart';

class DeleteAccountConfirmationScreen extends StatefulWidget {
  final VoidCallback onAccountDeleted;
  final VoidCallback onBack;
  
  const DeleteAccountConfirmationScreen({
    super.key,
    required this.onAccountDeleted,
    required this.onBack,
  });

  @override
  State<DeleteAccountConfirmationScreen> createState() => _DeleteAccountConfirmationScreenState();
}

class _DeleteAccountConfirmationScreenState extends State<DeleteAccountConfirmationScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();
  bool _isObscurePassword = true;
  bool _isObscureConfirmation = true;
  bool _isLoading = false;
  bool _understandConsequences = false;
  bool _dataWillBeDeleted = false;
  bool _cannotBeUndone = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteAccount() async {
    if (!_understandConsequences || !_dataWillBeDeleted || !_cannotBeUndone) {
      CustomSnackbar.show(
        context,
        CustomSnackbar(
          message: 'Please confirm that you understand all consequences',
          type: SnackbarType.error,
        ),
      );
      return;
    }

    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      CustomSnackbar.show(
        context,
        CustomSnackbar(
          message: 'Please enter your password to confirm',
          type: SnackbarType.error,
        ),
      );
      return;
    }

    final confirmation = _confirmationController.text.trim();
    if (confirmation != 'DELETE') {
      CustomSnackbar.show(
        context,
        CustomSnackbar(
          message: 'Please type "DELETE" exactly to confirm',
          type: SnackbarType.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthState>();
      
      // Immediately delete the account
      await authState.deleteAccount();
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Account deleted successfully.',
            type: SnackbarType.success,
          ),
        );
        
        // Notify that account deletion has been requested
        widget.onAccountDeleted();
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
            message: 'Failed to request account deletion. Please try again.',
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
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permanently remove your PocketLLM account and all associated data immediately',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Warning box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Theme.of(context).colorScheme.error,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Important',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Deleting your account is permanent and cannot be undone. All your data will be permanently removed from our systems immediately.',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Consequences checklist
                  const Text(
                    'Before proceeding, please confirm you understand:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  CustomCheckbox(
                    value: _understandConsequences,
                    onChanged: (value) {
                      setState(() {
                        _understandConsequences = value ?? false;
                      });
                    },
                    label: 'I understand that all my data will be permanently deleted',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  CustomCheckbox(
                    value: _dataWillBeDeleted,
                    onChanged: (value) {
                      setState(() {
                        _dataWillBeDeleted = value ?? false;
                      });
                    },
                    label: 'My conversations, settings, and profile information will be deleted',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  CustomCheckbox(
                    value: _cannotBeUndone,
                    onChanged: (value) {
                      setState(() {
                        _cannotBeUndone = value ?? false;
                      });
                    },
                    label: 'This action cannot be undone',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Password field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Current Password',
                    hintText: 'Enter your current password',
                    obscureText: _isObscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscurePassword = !_isObscurePassword;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Confirmation field
                  CustomTextField(
                    controller: _confirmationController,
                    label: 'Confirm Immediate Deletion',
                    hintText: 'Type "DELETE" to confirm immediate deletion',
                    obscureText: _isObscureConfirmation,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscureConfirmation ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscureConfirmation = !_isObscureConfirmation;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Delete Account button
                  CustomButton(
                    text: 'Delete Account',
                    onPressed: _isLoading ? () {} : _handleDeleteAccount,
                    variant: ButtonVariant.filled,
                    size: ButtonSize.large,
                    enabled: _understandConsequences && _dataWillBeDeleted && _cannotBeUndone,
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