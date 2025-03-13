import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:pocketllm/services/auth_service.dart';
import '../../widgets/clear_text_field.dart';
import 'user_survey_page.dart';
import '../settings/profile_settings.dart';

class AuthPage extends StatefulWidget {
  final Function(String email) onLoginSuccess;
  final bool showAppBar;

  const AuthPage({
    Key? key,
    required this.onLoginSuccess,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isValidEmail = false;
  bool _showPasswordField = false;
  bool _showSignupFields = false;
  bool _isLoading = false;
  bool _emailExists = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  late String _randomAvatar;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _randomAvatar = random.nextBool() ? 'assets/avatar1.jpg' : 'assets/avatar2.jpg';
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  Future<void> _handleEmailCheck() async {
    if (!_isValidEmail) return;

    try {
      setState(() => _isLoading = true);
      
      final exists = await _authService.checkEmailExists(_emailController.text);
      
      if (!mounted) return;
      setState(() {
        _emailExists = exists;
        _isLoading = false;
        _showPasswordField = true;
        _showSignupFields = !exists;
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email already registered. Please sign in.'),
              backgroundColor: Color(0xFF8B5CF6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New email detected. Please create an account.'),
              backgroundColor: Color(0xFF8B5CF6),
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error checking email: ${e.toString()}');
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  Future<void> _handleSignIn() async {
    if (_passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter your password');
      return;
    }
    
    try {
      setState(() => _isLoading = true);
      
      final response = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (response.user != null) {
        widget.onLoginSuccess(_emailController.text);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Login failed: ${e.toString()}');
    }
  }
  
  Future<void> _handleSignUp() async {
    if (_passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter a password');
      return;
    }
    
    if (_passwordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }
    
    try {
      setState(() => _isLoading = true);
      
      final response = await _authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please complete your profile.'),
            backgroundColor: Color(0xFF8B5CF6),
          ),
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserSurveyPage(
              userId: response.user!.id,
              onComplete: () => widget.onLoginSuccess(_emailController.text),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Signup failed: ${e.toString()}');
    }
  }

  void _forgotPassword() {
    if (!_isValidEmail) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset instructions to ${_emailController.text}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                await _authService.resetPassword(_emailController.text);
                if (!mounted) return;
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset instructions sent to your email'),
                    backgroundColor: Color(0xFF8B5CF6),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _isLoading = false);
                _showErrorSnackBar('Error sending reset instructions: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Instructions'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(_randomAvatar),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _showSignupFields ? 'Create Account' : (_showPasswordField ? 'Welcome Back' : 'Welcome'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (!_showPasswordField) ...[
              ClearTextField(
                controller: _emailController,
                hintText: 'Email',
                onChanged: (value) {
                  setState(() {
                    _isValidEmail = _validateEmail(value);
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isValidEmail && !_isLoading ? _handleEmailCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
            if (_showPasswordField && !_showSignupFields) ...[
              Text(
                _emailController.text,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFF8B5CF6)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: !_isLoading 
                        ? () => setState(() {
                            _showPasswordField = false;
                            _passwordController.clear();
                          })
                        : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : const Text('Sign In'),
                    ),
                  ),
                ],
              ),
            ],
            if (_showSignupFields) ...[
              Text(
                _emailController.text,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  hintText: 'Create Password',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: !_isLoading 
                        ? () => setState(() {
                            _showPasswordField = false;
                            _showSignupFields = false;
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          })
                        : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : const Text('Sign Up'),
                    ),
                  ),
                ],
              ),
            ],
            if (!_showPasswordField) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google Sign In is not available at the moment'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Color(0xFF8B5CF6),
                    ),
                  );
                },
                icon: Image.asset('assets/google.png', height: 24),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return widget.showAppBar
        ? Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              backgroundColor: Colors.grey[50],
              elevation: 0,
              title: const Text(
                'Account',
                style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            body: content,
          )
        : content;
  }
}