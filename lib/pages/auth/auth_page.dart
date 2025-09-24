import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import 'user_survey_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    this.onAuthenticated,
    this.onSkip,
    this.showAppBar = true,
    this.allowSkip = false,
  });

  final void Function(BuildContext context)? onAuthenticated;
  final void Function(BuildContext context)? onSkip;
  final bool showAppBar;
  final bool allowSkip;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _formMessage;
  bool _hasNavigated = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeNavigateOnAuth();
  }

  void _maybeNavigateOnAuth() {
    final authService = context.read<AuthService>();
    if (authService.isAuthenticated && !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAuthenticated?.call(context);
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (_isSignUp && value.length < 8) {
      return 'Use at least 8 characters for a secure password';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      setState(() => _formMessage = 'Please correct the highlighted fields.');
      return;
    }

    if (_isSignUp && _passwordController.text != _confirmPasswordController.text) {
      setState(() => _formMessage = 'Passwords do not match.');
      return;
    }

    final authService = context.read<AuthService>();
    setState(() {
      _isLoading = true;
      _formMessage = null;
    });

    AuthResult result;
    if (_isSignUp) {
      result = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      result = await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _formMessage = result.message;
    });

    if (result.success) {
      if (!result.requiresEmailConfirmation) {
        await authService.clearAuthSkip();
      }

      if (_isSignUp && !result.requiresEmailConfirmation) {
        final profile = context.read<AuthService>().currentProfile;
        if (profile != null) {
          final parentContext = context;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (pageContext) => UserSurveyPage(
                userId: profile.id,
                onComplete: () {
                  widget.onAuthenticated?.call(parentContext);
                },
              ),
            ),
          );
        }
      } else if (_isSignUp && result.requiresEmailConfirmation) {
        // Email verification required before continuing.
      } else {
        widget.onAuthenticated?.call(context);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _formMessage = 'Enter a valid email to reset password.');
      return;
    }

    final authService = context.read<AuthService>();
    final result = await authService.resetPassword(_emailController.text.trim());
    if (!mounted) return;
    setState(() => _formMessage = result.message);
  }

  Future<void> _handleSkip() async {
    await context.read<AuthService>().markAuthSkipped();
    widget.onSkip?.call(context);
  }

  Widget _buildComingSoonButton({required IconData icon, required String label}) {
    return Opacity(
      opacity: 0.5,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: Icon(icon, size: 24),
        label: Text('$label (Coming Soon)'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildForm(AuthService authService) {
    final canAuthenticate = authService.canAttemptAuthentication;

    if (!canAuthenticate) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Color(0xFF8B5CF6)),
          const SizedBox(height: 24),
          const Text(
            'Authentication is currently unavailable.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            authService.errorMessage ??
                'Set SUPABASE_URL and SUPABASE_ANON_KEY to enable secure sign in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (widget.allowSkip) ...[
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: _isLoading ? null : _handleSkip,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continue without an account'),
            ),
          ],
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToggleButtons(
            isSelected: [_isSignUp == false, _isSignUp],
            borderRadius: BorderRadius.circular(12),
            constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
            onPressed: (index) {
              if (_isLoading) return;
              setState(() {
                _isSignUp = index == 1;
                _formMessage = null;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Sign In'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Create Account'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            validator: _validatePassword,
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_isSignUp ? 'Create account' : 'Sign in'),
          ),
          if (widget.allowSkip) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : _handleSkip,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Maybe later'),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('More options'),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          _buildComingSoonButton(
            icon: Icons.g_mobiledata,
            label: 'Continue with Google',
          ),
          const SizedBox(height: 12),
          _buildComingSoonButton(
            icon: Icons.apple,
            label: 'Continue with Apple',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    final content = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Welcome to PocketLLM',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Sign in or create an account to sync your data across devices.'),
              ],
            ),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _formMessage == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(_formMessage),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formMessage!,
                        style: const TextStyle(color: Color(0xFF4C1D95)),
                      ),
                    ),
            ),
            _buildForm(authService),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          title: const Text(
            'Account',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        body: content,
      );
    }

    return content;
  }
}
