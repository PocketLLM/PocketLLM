/// File Overview:
/// - Purpose: Handles sign-in and sign-up UI, including survey handoff.
/// - Backend Migration: Keep but ensure it relies solely on backend auth flows
///   without local shortcuts or stored preferences for auth state.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../services/auth_state.dart';
import '../../services/backend_api_service.dart';
import '../../widgets/clear_text_field.dart';
import 'user_survey_page.dart';

enum _AuthMode { signIn, signUp }

class _StaggeredCurve extends Curve {
  const _StaggeredCurve({
    required this.delayFraction,
    this.curve = Curves.easeOutCubic,
  });

  final double delayFraction;
  final Curve curve;

  @override
  double transform(double t) {
    if (delayFraction >= 1) {
      return curve.transform(1);
    }
    if (t <= delayFraction) {
      return 0;
    }
    final normalized = ((t - delayFraction) / (1 - delayFraction)).clamp(0.0, 1.0);
    return curve.transform(normalized);
  }
}

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
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _waitlistNameController = TextEditingController();
  final TextEditingController _waitlistEmailController = TextEditingController();
  final TextEditingController _waitlistOccupationController = TextEditingController();
  final TextEditingController _waitlistMotivationController = TextEditingController();
  final TextEditingController _waitlistUseCaseController = TextEditingController();
  final TextEditingController _waitlistLinksController = TextEditingController();
  final GlobalKey<FormState> _waitlistFormKey = GlobalKey<FormState>();
  final BackendApiService _backendApi = BackendApiService();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  static final RegExp _emailRegex =
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSurveyActive = false;
  bool _waitlistSuccess = false;
  String? _waitlistStatusMessage;

  void _log(String message) {
    debugPrint('[AuthPage] $message');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
    _waitlistNameController.dispose();
    _waitlistEmailController.dispose();
    _waitlistOccupationController.dispose();
    _waitlistMotivationController.dispose();
    _waitlistUseCaseController.dispose();
    _waitlistLinksController.dispose();
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
                if (authState.isServiceAvailable)
                  _buildAuthForm(context, authState)
                else
                  _buildUnavailableState(),
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
        if (authState.isServiceAvailable)
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
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final selectedColor = _lightenPrimary(primary);
    final textColor = selected ? primary : Colors.grey[700];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Color _lightenPrimary(Color color) {
    final hsl = HSLColor.fromColor(color);
    final lighter = hsl.withLightness((hsl.lightness + 0.35).clamp(0.0, 1.0));
    return lighter.toColor();
  }

  Widget _buildInviteCodeSection() {
    if (_mode != _AuthMode.signUp) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _inviteCodeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Invite or referral code',
            hintText: 'e.g. HELLO-1234'
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            Text(
              'Need an invite?',
              style: TextStyle(color: Colors.grey[700]),
            ),
            TextButton(
              onPressed: _openWaitlistSheet,
              child: const Text('Apply for access'),
            ),
          ],
        ),
        if (_waitlistStatusMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            _waitlistStatusMessage!,
            style: TextStyle(
              fontSize: 13,
              color: _waitlistSuccess ? Colors.green[700] : Colors.red[600],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openWaitlistSheet() async {
    _waitlistFormKey.currentState?.reset();
    _waitlistNameController.text = _deriveSuggestedName();
    _waitlistEmailController.text = _emailController.text.trim();
    _waitlistOccupationController.clear();
    _waitlistMotivationController.clear();
    _waitlistUseCaseController.clear();
    _waitlistLinksController.clear();

    if (!mounted) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        bool isSubmitting = false;

        Future<void> submit(StateSetter setModalState) async {
          final isValid = _waitlistFormKey.currentState?.validate() ?? false;
          if (!isValid) {
            return;
          }
          setModalState(() {
            isSubmitting = true;
          });
          try {
            final payload = _buildWaitlistPayload();
            await _backendApi.post('/waitlist', body: payload);
            if (!mounted) return;
            Navigator.of(modalContext).pop(true);
            _showSnackBar(context, 'Application received! We will be in touch soon.', success: true);
          } on BackendApiException catch (error) {
            setModalState(() {
              isSubmitting = false;
            });
            _showSnackBar(context, error.message, success: false);
          } catch (error) {
            setModalState(() {
              isSubmitting = false;
            });
            _showSnackBar(context, 'Failed to submit application: $error', success: false);
          }
        }

        return StatefulBuilder(
          builder: (innerContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Form(
                    key: _waitlistFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Apply for PocketLLM access',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(modalContext).pop(false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _waitlistNameController,
                          decoration: const InputDecoration(labelText: 'Full name'),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Please share your name' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _waitlistEmailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!_emailRegex.hasMatch(value.trim())) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _waitlistOccupationController,
                          decoration: const InputDecoration(labelText: 'Occupation'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _waitlistMotivationController,
                          decoration: const InputDecoration(
                            labelText: 'Why do you want access?',
                            hintText: 'Share what you are building or researching',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _waitlistUseCaseController,
                          decoration: const InputDecoration(
                            labelText: 'How will you use PocketLLM?',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _waitlistLinksController,
                          decoration: const InputDecoration(
                            labelText: 'Links (optional)',
                            helperText: 'Comma separated portfolio, LinkedIn, or project links.',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : () => submit(setModalState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Submit application'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result == true) {
      setState(() {
        _waitlistSuccess = true;
        _waitlistStatusMessage = 'Application received! We will notify you via email.';
      });
    }
  }

  Map<String, dynamic> _buildWaitlistPayload() {
    final links = _parseLinksInput(_waitlistLinksController.text);
    final payload = <String, dynamic>{
      'name': _waitlistNameController.text.trim(),
      'email': _waitlistEmailController.text.trim(),
      'occupation': _trimOrNull(_waitlistOccupationController.text),
      'motivation': _trimOrNull(_waitlistMotivationController.text),
      'use_case': _trimOrNull(_waitlistUseCaseController.text),
      'links': links.isEmpty ? null : links,
      'source': 'app_auth',
      'metadata': {
        'platform': 'flutter_app',
        'build': kReleaseMode ? 'release' : 'debug',
      },
    };
    payload.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String) {
        return value.trim().isEmpty;
      }
      if (value is Iterable && value.isEmpty) {
        return true;
      }
      return false;
    });
    return payload;
  }

  List<String> _parseLinksInput(String value) {
    if (value.trim().isEmpty) {
      return const [];
    }
    final segments = value.split(RegExp(r'[,\n]'));
    return segments.map((segment) => segment.trim()).where((segment) => segment.isNotEmpty).toList();
  }

  String? _trimOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _deriveSuggestedName() {
    final existing = _waitlistNameController.text.trim();
    if (existing.isNotEmpty) {
      return existing;
    }
    final email = _emailController.text.trim();
    if (email.contains('@')) {
      final handle = email.split('@').first;
      if (handle.isNotEmpty) {
        return handle.replaceAll(RegExp(r'[\.\_\-]+'), ' ').trim();
      }
    }
    return '';
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, animation) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slideAnimation, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_mode),
            child: Form(
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
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      final normalizedValue = value.trim();
                      if (!_emailRegex.hasMatch(normalizedValue)) {
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
          ),
        ),
        if (isSignUp) ...[
          const SizedBox(height: 16),
          _buildInviteCodeSection(),
        ],
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
    final options = <({String label, Widget icon, VoidCallback? onPressed})>[
      (
        label: 'Google',
        icon: SvgPicture.asset('assets/brand_icons/google.svg', height: 28),
        onPressed: () => _showComingSoonMessage(context, 'Google Sign-In is coming soon. Please use email and password for now.'),
      ),
      (
        label: 'Facebook',
        icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 28),
        onPressed: () => _showComingSoonMessage(context, 'Facebook Sign-In is coming soon. Please use email and password for now.'),
      ),
      (
        label: 'GitHub',
        icon: SvgPicture.asset('assets/brand_icons/github.svg', height: 28),
        onPressed: () => _showComingSoonMessage(context, 'GitHub Sign-In is coming soon. Please use email and password for now.'),
      ),
      (
        label: 'Phone',
        icon: const Icon(Icons.phone, color: Color(0xFF6D28D9), size: 26),
        onPressed: () => _showComingSoonMessage(context, 'Phone Sign-In is coming soon. Please use email and password for now.'),
      ),
    ];

    Widget buildOption(int index) {
      final option = options[index];

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: _StaggeredCurve(
          delayFraction: (index * 0.08).clamp(0.0, 0.7),
        ),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        ),
        child: GestureDetector(
          onTap: option.onPressed,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: '${option.label} coming soon',
                child: SizedBox(
                  height: 48,
                  child: Center(child: option.icon),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 480 ? 12.0 : 8.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int index = 0; index < options.length; index++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                  child: buildOption(index),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUnavailableState() {
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Authentication is currently unavailable. Please try again later or reach out to support if the issue persists.',
                  style: TextStyle(color: Colors.orange[800]),
                ),
              ),
            ],
          ),
        ),
        if (widget.allowSkip) ...[
          const SizedBox(height: 24),
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
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    _log('Attempting submission for email=$email');

    try {
      if (_mode == _AuthMode.signIn) {
        _log('Starting sign-in flow.');
        final result = await authState.signInWithEmail(email: email, password: password);
        if (!mounted) return;

        _log('Sign-in completed. canceledDeletion=${result.canceledDeletion}, profileLoaded=${authState.profile != null}');

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
        _log('Starting sign-up flow.');
        final inviteCode = _inviteCodeController.text.trim();
        final result = await authState.signUpWithEmail(
          email: email,
          password: password,
          inviteCode: inviteCode.isEmpty ? null : inviteCode,
        );
        if (!mounted) return;

        _log('Sign-up completed. userId=${result.userId}, emailConfirmationRequired=${result.emailConfirmationRequired}');

        if (result.emailConfirmationRequired) {
          await _clearAuthSkipFlag();
          final message = (result.message?.isNotEmpty ?? false)
              ? result.message!
              : 'Please check your email to confirm your account before continuing.';
          _showSnackBar(
            context,
            message,
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
      _log('Authentication error surfaced to UI: ${e.message}');
      _showSnackBar(context, e.message, success: false);
    } on StateError catch (e) {
      _log('State error surfaced to UI: ${e.message}');
      _showSnackBar(context, e.message, success: false);
    } catch (e) {
      _log('Unexpected error surfaced to UI: $e');
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
    
    // Provide more user-friendly error messages
    String displayMessage = message;
    if (!success) {
      if (message.contains('Failed to parse backend response') || 
          message.contains('Unexpected character')) {
        displayMessage = 'Server error. Please try again later.';
      } else if (message.contains('SocketException') || 
                 message.contains('Failed host lookup') ||
                 message.contains('Unable to reach')) {
        displayMessage = 'Please check your internet connection and try again.';
      } else if (message.contains('500')) {
        displayMessage = 'Server error. Please try again later.';
      } else if (message.contains('Unable to validate invite status')) {
        displayMessage = 'Unable to validate invite status. Please check your invite code or apply for access.';
      } else if (message.contains('invite code or approved waitlist application is required')) {
        displayMessage = 'An invite code or approved waitlist application is required to create an account.';
      }
    }
    
    messenger.showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        backgroundColor: success ? const Color(0xFF8B5CF6) : Colors.redAccent,
      ),
    );
  }

  void _showComingSoonMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange, // Yellow/orange for "coming soon" notifications
      ),
    );
  }

  Future<void> _clearAuthSkipFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authSkipped');
  }
}
