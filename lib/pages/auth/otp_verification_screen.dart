import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../services/auth_state.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_snackbar.dart';
import '../../widgets/auth/otp_input.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onBackToSignIn;
  final VoidCallback onVerificationSuccess;
  
  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.onBackToSignIn,
    required this.onVerificationSuccess,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  String _otpCode = '';
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

  Future<void> _handleVerifyOTP(String code) async {
    if (code.length != 6) return;
    
    setState(() => _isVerifying = true);
    
    try {
      // In a real implementation, we would call the backend API to verify the OTP
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate verification success
      if (mounted) {
        setState(() => _isVerifying = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'OTP verified successfully!',
            type: SnackbarType.success,
          ),
        );
        
        // Navigate to reset password screen or next step
        widget.onVerificationSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Invalid OTP code. Please try again.',
            type: SnackbarType.error,
          ),
        );
        
        // Clear the OTP input
        setState(() {
          _otpCode = '';
        });
      }
    }
  }

  Future<void> _handleResendOTP() async {
    setState(() => _isResending = true);
    
    try {
      // In a real implementation, we would call the backend API to resend the OTP
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() => _isResending = false);
        
        // Show success message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'OTP resent to ${widget.email}',
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
            message: 'Failed to resend OTP. Please try again.',
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
                    'Verify your email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code sent to ${widget.email}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // OTP Input
                  OTPInput(
                    length: 6,
                    onCompleted: _handleVerifyOTP,
                    onChanged: (code) {
                      setState(() {
                        _otpCode = code;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
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
                          onPressed: _isResending ? null : _handleResendOTP,
                          child: const Text('Resend code'),
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
                  
                  const SizedBox(height: 32),
                  
                  // Verify button
                  CustomButton(
                    text: 'Verify',
                    onPressed: _isVerifying ? () {} : () => _handleVerifyOTP(_otpCode),
                    variant: ButtonVariant.filled,
                    size: ButtonSize.large,
                  ),
                  
                  if (_isVerifying)
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

// Extension to add clear and getCode methods to OTPInput
