import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../services/auth_state.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_snackbar.dart';
import '../../widgets/auth/segmented_control.dart';
import '../../theme/app_colors.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;
  final VoidCallback onBack;
  
  const TwoFactorSetupScreen({
    super.key,
    required this.onSetupComplete,
    required this.onBack,
  });

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _totpCodeController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();
  final TextEditingController _emailCodeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isVerifying = false;
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
    _totpCodeController.dispose();
    _smsCodeController.dispose();
    _emailCodeController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
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

  Future<void> _handleVerifyTOTP() async {
    final code = _totpCodeController.text.trim();
    if (code.length != 6) {
      CustomSnackbar.show(
        context,
        const CustomSnackbar(
          message: 'Please enter a 6-digit code',
          type: SnackbarType.error,
        ),
      );
      return;
    }
    
    setState(() => _isVerifying = true);
    
    try {
      // In a real implementation, we would call the backend API to verify the TOTP code
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isVerifying = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          const CustomSnackbar(
            message: '2FA enabled successfully!',
            type: SnackbarType.success,
          ),
        );
        
        // Navigate to the next screen or complete the setup
        widget.onSetupComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          const CustomSnackbar(
            message: 'Invalid code. Please try again.',
            type: SnackbarType.error,
          ),
        );
        
        // Clear the code input
        setState(() {
          _totpCodeController.clear();
        });
      }
    }
  }

  Future<void> _handleVerifySMS() async {
    final code = _smsCodeController.text.trim();
    if (code.length != 6) {
      CustomSnackbar.show(
        context,
        const CustomSnackbar(
          message: 'Please enter a 6-digit code',
          type: SnackbarType.error,
        ),
      );
      return;
    }
    
    setState(() => _isVerifying = true);
    
    try {
      // In a real implementation, we would call the backend API to verify the SMS code
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isVerifying = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          const CustomSnackbar(
            message: '2FA enabled successfully!',
            type: SnackbarType.success,
          ),
        );
        
        // Navigate to the next screen or complete the setup
        widget.onSetupComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          const CustomSnackbar(
            message: 'Invalid code. Please try again.',
            type: SnackbarType.error,
          ),
        );
        
        // Clear the code input
        setState(() {
          _smsCodeController.clear();
        });
      }
    }
  }

  Future<void> _handleVerifyEmail() async {
    final code = _emailCodeController.text.trim();
    if (code.length != 6) {
      CustomSnackbar.show(
        context,
        const CustomSnackbar(
          message: 'Please enter a 6-digit code',
          type: SnackbarType.error,
        ),
      );
      return;
    }
    
    setState(() => _isVerifying = true);
    
    try {
      // In a real implementation, we would call the backend API to verify the email code
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isVerifying = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          const CustomSnackbar(
            message: '2FA enabled successfully!',
            type: SnackbarType.success,
          ),
        );
        
        // Navigate to the next screen or complete the setup
        widget.onSetupComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          const CustomSnackbar(
            message: 'Invalid code. Please try again.',
            type: SnackbarType.error,
          ),
        );
        
        // Clear the code input
        setState(() {
          _emailCodeController.clear();
        });
      }
    }
  }

  Future<void> _handleResendCode() async {
    setState(() => _isResending = true);
    
    try {
      // In a real implementation, we would call the backend API to resend the code
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() => _isResending = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          const CustomSnackbar(
            message: 'Code resent successfully',
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
          const CustomSnackbar(
            message: 'Failed to resend code. Please try again.',
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
                    'Set up two-factor authentication',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add an extra layer of security to your account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Segmented Control for 2FA methods
                  SegmentedControl(
                    selectedIndex: _selectedTabIndex,
                    options: const ['Authenticator App', 'SMS', 'Email'],
                    onSelectionChanged: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Content based on selected tab
                  if (_selectedTabIndex == 0) 
                    _buildTOTPContent()
                  else if (_selectedTabIndex == 1)
                    _buildSMSContent()
                  else
                    _buildEmailContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTOTPContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instructions
        Text(
          '1. Scan the QR code with your authenticator app',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // QR Code placeholder
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColorTokens.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColorTokens.brandSecondaryVariant),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code,
                  size: 80,
                  color: AppColorTokens.brandPrimary,
                ),
                SizedBox(height: 16),
                Text(
                  'QR Code Placeholder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          '2. Enter the 6-digit code from your app',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // TOTP Code Input
        CustomTextField(
          controller: _totpCodeController,
          label: '6-digit code',
          hintText: 'Enter code',
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 32),
        
        // Verify button
        CustomButton(
          text: 'Verify and Enable',
          onPressed: _isVerifying ? () {} : _handleVerifyTOTP,
          variant: ButtonVariant.filled,
          size: ButtonSize.large,
        ),
        
        if (_isVerifying)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildSMSContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone number input
        CustomTextField(
          controller: _phoneNumberController,
          label: 'Phone number',
          hintText: 'Enter your phone number',
          keyboardType: TextInputType.phone,
        ),
        
        const SizedBox(height: 24),
        
        // Instructions
        Text(
          '1. We\'ll send a code to your phone number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // Send code button
        CustomButton(
          text: 'Send Code',
          onPressed: _isResending ? () {} : _handleResendCode,
          variant: ButtonVariant.tonal,
          size: ButtonSize.large,
        ),
        
        const SizedBox(height: 24),
        
        Text(
          '2. Enter the 6-digit code we sent',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // SMS Code Input
        CustomTextField(
          controller: _smsCodeController,
          label: '6-digit code',
          hintText: 'Enter code',
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 16),
        
        // Resend section
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _resendTimer > 0 
                ? 'Resend in 0:$_resendTimer' 
                : 'Didn\'t receive the code?',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (_resendTimer <= 0) ...[
              TextButton(
                onPressed: _isResending ? null : _handleResendCode,
                child: const Text('Resend code'),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Verify button
        CustomButton(
          text: 'Verify and Enable',
          onPressed: _isVerifying ? () {} : _handleVerifySMS,
          variant: ButtonVariant.filled,
          size: ButtonSize.large,
        ),
        
        if (_isVerifying)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildEmailContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email input
        CustomTextField(
          controller: _emailController,
          label: 'Email address',
          hintText: 'Enter your email address',
          keyboardType: TextInputType.emailAddress,
        ),
        
        const SizedBox(height: 24),
        
        // Instructions
        Text(
          '1. We\'ll send a code to your email address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // Send code button
        CustomButton(
          text: 'Send Code',
          onPressed: _isResending ? () {} : _handleResendCode,
          variant: ButtonVariant.tonal,
          size: ButtonSize.large,
        ),
        
        const SizedBox(height: 24),
        
        Text(
          '2. Enter the 6-digit code we sent',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // Email Code Input
        CustomTextField(
          controller: _emailCodeController,
          label: '6-digit code',
          hintText: 'Enter code',
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 16),
        
        // Resend section
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _resendTimer > 0 
                ? 'Resend in 0:$_resendTimer' 
                : 'Didn\'t receive the code?',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (_resendTimer <= 0) ...[
              TextButton(
                onPressed: _isResending ? null : _handleResendCode,
                child: const Text('Resend code'),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Verify button
        CustomButton(
          text: 'Verify and Enable',
          onPressed: _isVerifying ? () {} : _handleVerifyEmail,
          variant: ButtonVariant.filled,
          size: ButtonSize.large,
        ),
        
        if (_isVerifying)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}