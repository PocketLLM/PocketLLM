import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_state.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/stepper.dart';
import '../../widgets/auth/custom_snackbar.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const ProfileCompletionScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  int _currentStep = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (_currentStep == 1) {
      if (_formKeyStep1.currentState?.validate() != true) return;
      setState(() => _currentStep = 2);
      return;
    }
    
    if (_formKeyStep2.currentState?.validate() != true) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final authState = context.read<AuthState>();
      
      // Update the user's profile
      await authState.completeProfile(
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        onboarding: {'surveyCompleted': true},
      );
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Profile completed successfully!',
            type: SnackbarType.success,
          ),
        );
        
        // Complete the profile setup
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Failed to complete profile. Please try again.',
            type: SnackbarType.error,
          ),
        );
      }
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        leading: _currentStep > 1
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
                onPressed: _goToPreviousStep,
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
                  const SizedBox(height: 16),
                  
                  // Stepper
                  CustomStepper(
                    currentStep: _currentStep,
                    maxSteps: 2,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Header
                  Text(
                    _currentStep == 1 
                        ? 'Complete your profile' 
                        : 'Complete your profile',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep == 1
                        ? 'Tell us a bit about yourself so we can personalize your experience.'
                        : 'Add a few more details so we can personalize your experience.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Form based on current step
                  if (_currentStep == 1) ...[
                    Form(
                      key: _formKeyStep1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hintText: 'Enter your full name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _usernameController,
                            label: 'Username',
                            hintText: 'Choose a username',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please choose a username';
                              }
                              if (value.trim().length < 3) {
                                return 'Username must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Form(
                      key: _formKeyStep2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _bioController,
                            label: 'Bio (optional)',
                            hintText: 'Tell us about yourself',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Action Button
                  CustomButton(
                    text: _currentStep == 1 ? 'Continue' : 'Finish',
                    onPressed: _isSubmitting ? () {} : _submitProfile,
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
          ),
        ),
      ),
    );
  }
}