import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../services/auth_state.dart';
import '../../widgets/clear_text_field.dart';
import 'user_survey_page.dart';

enum _AuthMode { signIn, signUp }

class AuthPage extends StatefulWidget {
  final ValueChanged<String>? onLoginSuccess;
  final bool showAppBar;
  final bool allowSkip;
  final VoidCallback? onSkip;

  const AuthPage({
    super.key,
    this.onLoginSuccess,
    this.showAppBar = true,
    this.allowSkip = false,
    this.onSkip,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSurveyActive = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final content = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildHeader(authState),
                const SizedBox(height: 32),
                if (!authState.isServiceAvailable) ...[
                  _buildServiceWarning(authState),
                  const SizedBox(height: 24),
                ],
                _buildAuthForm(context, authState),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: const Text(
          'Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: content,
    );
  }

  Widget _buildHeader(AuthState authState) {
    if (authState.isAuthenticated && authState.profile != null) {
      final profile = authState.profile!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${profile.fullName ?? profile.email}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re already signed in. Review your details or continue to PocketLLM.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      );
    }

    final isSignUp = _mode == _AuthMode.signUp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSignUp ? 'Create your PocketLLM account' : 'Welcome back to PocketLLM',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSignUp
              ? 'Unlock personalized AI experiences by creating an account.'
              : 'Sign in to access your personalized workspace.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  label: 'Sign In',
                  selected: _mode == _AuthMode.signIn,
                  onTap: () {
                    setState(() {
                      _mode = _AuthMode.signIn;
                    });
                  },
                ),
              ),
              Expanded(
                child: _buildModeButton(
                  label: 'Sign Up',
                  selected: _mode == _AuthMode.signUp,
                  onTap: () {
                    setState(() {
                      _mode = _AuthMode.signUp;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8B5CF6) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm(BuildContext context, AuthState authState) {
    if (authState.isAuthenticated) {
      if (authState.profile == null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: CircularProgressIndicator(),
          ),
        );
      }
      return _buildAuthenticatedView(context, authState);
    }

    final isSignUp = _mode == _AuthMode.signUp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClearTextField(
                controller: _emailController,
                focusNode: _emailFocus,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  final emailRegex = RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\\$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: isSignUp ? 'Create Password' : 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              if (isSignUp) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
        if (_mode == _AuthMode.signIn)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showPasswordResetInfo(context),
              child: const Text('Forgot password?'),
            ),
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: authState.isPerformingRequest ? null : () => _handleSubmit(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: authState.isPerformingRequest
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(isSignUp ? 'Create Account' : 'Sign In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        _buildDivider(),
        const SizedBox(height: 16),
        _buildComingSoonButtons(),
        if (widget.allowSkip) ...[
          const SizedBox(height: 32),
          TextButton(
            onPressed: widget.onSkip,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
            ),
            child: const Text('Skip for now'),
          ),
        ],
      ],
    );
  }

  Widget _buildAuthenticatedView(BuildContext context, AuthState authState) {
    final UserProfile profile = authState.profile!;
    final themeColor = const Color(0xFF8B5CF6);
    final avatarUrl = profile.avatarUrl;
    ImageProvider? avatarProvider;
    if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
      avatarProvider = NetworkImage(avatarUrl);
    }

    String _buildInitials() {
      final source = profile.fullName?.trim().isNotEmpty == true
          ? profile.fullName!
          : profile.email;
      final parts = source.trim().split(RegExp(r'\s+'));
      final buffer = StringBuffer();
      for (final part in parts) {
        if (part.isNotEmpty) {
          buffer.write(part.substring(0, 1).toUpperCase());
        }
        if (buffer.length == 2) break;
      }
      return buffer.isEmpty ? '?' : buffer.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: themeColor.withOpacity(0.12),
                  backgroundImage: avatarProvider,
                  child: avatarProvider == null
                      ? Text(
                          _buildInitials(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4C1D95),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName ?? profile.email,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (profile.hasPendingDeletion) ...[
          const SizedBox(height: 16),
          _buildDeletionBanner(profile),
        ],
        if (!profile.surveyCompleted) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.task_alt, color: Color(0xFF6D28D9)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Let\'s finish setting up your profile so we can personalise your experience.',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: 'Complete profile questionnaire',
            child: ElevatedButton(
              onPressed: _isSurveyActive ? null : () => _navigateToSurvey(authState),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Complete profile now'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Semantics(
          button: true,
          label: 'Continue to PocketLLM',
          child: ElevatedButton(
            onPressed: () => _handleContinue(authState),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue to PocketLLM'),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: 'Sign out',
          child: TextButton(
            onPressed: () => _handleSignOut(authState),
            child: const Text('Sign out'),
          ),
        ),
      ],
    );
  }

  Widget _buildDeletionBanner(UserProfile profile) {
    final timeLeft = profile.timeUntilDeletion;
    String subtitle = 'Account scheduled for deletion.';
    if (timeLeft != null) {
      final days = timeLeft.inDays;
      final hours = timeLeft.inHours.remainder(24);
      if (days > 0) {
        subtitle = '$subtitle ${days}d ${hours}h remaining.';
      } else if (hours > 0) {
        final minutes = timeLeft.inMinutes.remainder(60);
        subtitle = '$subtitle ${hours}h ${minutes}m remaining.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deletion pending',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContinue(AuthState authState) async {
    await _clearAuthSkipFlag();
    final email = authState.currentUserEmail ?? '';
    widget.onLoginSuccess?.call(email);
  }

  Future<void> _handleSignOut(AuthState authState) async {
    try {
      await authState.signOut();
      if (!mounted) return;
      setState(() {
        _mode = _AuthMode.signIn;
      });
      _showSnackBar(context, 'Signed out', success: true);
    } catch (e) {
      _showSnackBar(context, 'Unable to sign out: $e', success: false);
    }
  }

  Future<void> _navigateToSurvey(AuthState authState, {String? emailOverride}) async {
    if (_isSurveyActive) return;
    setState(() {
      _isSurveyActive = true;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserSurveyPage(
          onComplete: () {
            widget.onLoginSuccess?.call(emailOverride ?? authState.profile?.email ?? '');
          },
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _isSurveyActive = false;
    });
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: Colors.grey[600])),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildComingSoonButtons() {
    final buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      side: BorderSide(color: Colors.grey[300]!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      foregroundColor: Colors.grey[500],
    );

    Widget buildButton(String label, Widget leading) {
      return OutlinedButton(
        onPressed: null,
        style: buttonStyle,
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Coming Soon',
                style: TextStyle(color: Colors.amber[800], fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        buildButton(
          'Continue with Google',
          Image.asset('assets/google.png', height: 24, color: Colors.grey[500]),
        ),
        const SizedBox(height: 12),
        buildButton(
          'Continue with Apple',
          const Icon(Icons.apple, color: Colors.grey, size: 24),
        ),
      ],
    );
  }

  Widget _buildServiceWarning(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We\'re having trouble reaching the PocketLLM service. '
                      'You can still try to sign in or sign up, and we\'ll keep checking the connection in the background.',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    await authState.refreshServiceAvailability();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry connection'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.allowSkip) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8B5CF6),
              ),
              child: const Text('Continue without an account'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final authState = context.read<AuthState>();
    if (!authState.isServiceAvailable) {
      _showSnackBar(
        context,
        'Connection looks unstable. We\'ll keep retrying while attempting your request.',
      );
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_mode == _AuthMode.signIn) {
        final result = await authState.signInWithEmail(email: email, password: password);
        if (!mounted) return;

        await _clearAuthSkipFlag();
        final profile = authState.profile;
        final resolvedEmail = authState.currentUserEmail ?? email;

        if (profile != null && !profile.surveyCompleted) {
          final message = result.canceledDeletion
              ? 'Account deletion cancelled. Welcome back! Please finish your profile setup.'
              : 'Signed in successfully. Let\'s finish setting up your profile.';
          _showSnackBar(context, message, success: true);
          await _navigateToSurvey(authState, emailOverride: resolvedEmail);
        } else {
          widget.onLoginSuccess?.call(resolvedEmail);
          if (result.canceledDeletion) {
            _showSnackBar(context, 'Account deletion cancelled. Welcome back!', success: true);
          } else {
            _showSnackBar(context, 'Signed in successfully', success: true);
          }
        }
      } else {
        final result = await authState.signUpWithEmail(email: email, password: password);
        if (!mounted) return;

        if (result.emailConfirmationRequired) {
          await _clearAuthSkipFlag();
          _showSnackBar(
            context,
            'Please check your email to confirm your account before continuing.',
            success: true,
          );
          widget.onLoginSuccess?.call(authState.currentUserEmail ?? email);
        } else {
          await _clearAuthSkipFlag();
          _showSnackBar(
            context,
            result.message ?? 'Account created! Tell us a bit about yourself so we can personalise PocketLLM.',
            success: true,
          );
          await _navigateToSurvey(authState, emailOverride: authState.currentUserEmail ?? email);
        }
      }
    } on AuthException catch (e) {
      _showSnackBar(context, e.message, success: false);
    } on StateError catch (e) {
      _showSnackBar(context, e.message, success: false);
    } catch (e) {
      _showSnackBar(context, 'Something went wrong: $e', success: false);
    }
  }

  void _showPasswordResetInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password Reset'),
        content: const Text(
          'Password reset is coming soon. For now, contact support to regain access to your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, {bool success = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF8B5CF6) : Colors.redAccent,
      ),
    );
  }

  Future<void> _clearAuthSkipFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authSkipped');
  }
}
