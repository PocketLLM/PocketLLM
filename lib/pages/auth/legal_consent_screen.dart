import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_state.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_checkbox.dart';
import '../../widgets/auth/custom_snackbar.dart';
import '../../theme/app_colors.dart';

class LegalConsentScreen extends StatefulWidget {
  final VoidCallback onConsentGiven;
  final VoidCallback onBack;
  
  const LegalConsentScreen({
    super.key,
    required this.onConsentGiven,
    required this.onBack,
  });

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _acceptedMarketing = false;
  bool _isLoading = false;

  Future<void> _handleAcceptConsent() async {
    if (!_acceptedTerms) {
      CustomSnackbar.show(
        context,
        CustomSnackbar(
          message: 'Please accept the Terms of Service to continue',
          type: SnackbarType.error,
        ),
      );
      return;
    }

    if (!_acceptedPrivacy) {
      CustomSnackbar.show(
        context,
        CustomSnackbar(
          message: 'Please accept the Privacy Policy to continue',
          type: SnackbarType.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthState>();
      
      // In a real implementation, we would call the backend API to record consent
      // POST /consents { marketing: bool, termsVersion }
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Consent recorded successfully',
            type: SnackbarType.success,
          ),
        );
        
        // Navigate to the next screen
        widget.onConsentGiven();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Failed to record consent. Please try again.',
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
                    'Legal Agreements',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please review and accept our legal agreements to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Terms of Service
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CustomCheckbox(
                              value: _acceptedTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptedTerms = value ?? false;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Terms of Service',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'I have read and agree to the Terms of Service',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            // In a real app, this would open the terms of service in a web view
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Terms of Service would open in a web view'),
                              ),
                            );
                          },
                          child: const Text('Read Terms of Service'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Privacy Policy
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CustomCheckbox(
                              value: _acceptedPrivacy,
                              onChanged: (value) {
                                setState(() {
                                  _acceptedPrivacy = value ?? false;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'I have read and agree to the Privacy Policy',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            // In a real app, this would open the privacy policy in a web view
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Privacy Policy would open in a web view'),
                              ),
                            );
                          },
                          child: const Text('Read Privacy Policy'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Marketing Consent
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CustomCheckbox(
                              value: _acceptedMarketing,
                              onChanged: (value) {
                                setState(() {
                                  _acceptedMarketing = value ?? false;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Marketing Communications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'I agree to receive marketing communications',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Accept button
                  CustomButton(
                    text: 'Accept and Continue',
                    onPressed: _isLoading ? () {} : _handleAcceptConsent,
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