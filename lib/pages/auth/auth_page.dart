import 'package:flutter/material.dart';
// import 'package:pocketllm/services/auth_service.dart';
import 'package:pocketllm/services/local_db_service.dart';
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
  // final AuthService _authService = AuthService();
  final LocalDBService _localDBService = LocalDBService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isValidEmail = false;
  bool _showPasswordField = false;
  bool _showSignupFields = false;
  bool _isLoading = false;
  bool _emailExists = false;
  String _selectedAvatar = 'assets/avatar1.jpg';

  @override
  void initState() {
    super.initState();
    // Randomly select avatar1 or avatar2
    _selectedAvatar = 'assets/avatar${(DateTime.now().millisecondsSinceEpoch % 2) + 1}.jpg';
  }
  
  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  Future<void> _handleEmailCheck() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Check if email exists in local database
      final user = await _localDBService.getUserByEmail(_emailController.text);
      final exists = user != null;
      
      if (!mounted) return;
      setState(() {
        _emailExists = exists;
        _isLoading = false;
        _showPasswordField = true;
        
        // If the email exists, show the login form
        // If it doesn't, show the signup form
        _showSignupFields = !exists;
      });
      
      // Show appropriate message to the user based on email existence
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back! Please enter your password to sign in.'),
            backgroundColor: Color(0xFF8B5CF6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This email is not registered. Please create a new account.'),
            backgroundColor: Color(0xFF8B5CF6),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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
    
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Use local database for login
        await _localDBService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
        
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Color(0xFF8B5CF6),
          ),
        );
        widget.onLoginSuccess(_emailController.text);
      } catch (e) {
        throw e; // Re-throw to be caught by the outer catch block
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      // Check if it's an invalid credentials error
      if (e.toString().toLowerCase().contains('invalid email or password')) {
        _showErrorSnackBar('Incorrect password. Please try again or use "Forgot Password".');
      } else if (e.toString().toLowerCase().contains('user not found')) {
        // This case should be rare since we already checked if the email exists
        _showErrorSnackBar('No account found with this email. Please create an account.');
        setState(() {
          _emailExists = false;
          _showSignupFields = true;
        });
      } else {
        _showErrorSnackBar('Login failed: ${e.toString()}');
      }
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
    
    if (!mounted) return;
    try {
      // Check email existence one more time to ensure it doesn't exist
      final user = await _localDBService.getUserByEmail(_emailController.text);
      final exists = user != null;
      
      if (exists) {
        setState(() {
          _emailExists = true;
          _showSignupFields = false;
        });
        _showErrorSnackBar('This email is already registered. Please login instead.');
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      // Register user with local database
      final newUser = await _localDBService.register(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      // Clear any previous error messages
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Complete your profile to get started.'),
          backgroundColor: Color(0xFF8B5CF6),
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate to user survey page using pushAndRemoveUntil to clear the stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => UserSurveyPage(
            userId: newUser.id,
            onComplete: () {
              widget.onLoginSuccess(_emailController.text);
            },
          ),
        ),
        (route) => false, // This will remove all previous routes
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      if (e.toString().toLowerCase().contains('user with this email already exists')) {
        _showErrorSnackBar('This email is already registered. Please login instead.');
        setState(() {
          _emailExists = true;
          _showSignupFields = false;
        });
      } else {
        _showErrorSnackBar('Signup failed: ${e.toString()}');
      }
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
                await _localDBService.resetPassword(
                  email: _emailController.text,
                  newPassword: 'Reset123!', // Default password after reset
                );
                
                setState(() => _isLoading = false);
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset completed. Check your email for the new password'),
                    backgroundColor: Color(0xFF8B5CF6),
                  ),
                );
              } catch (e) {
                setState(() => _isLoading = false);
                
                if (!mounted) return;
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
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(_selectedAvatar),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _showSignupFields 
                ? 'Create New Account' 
                : (_showPasswordField 
                    ? (_emailExists ? 'Welcome Back' : 'Create New Account') 
                    : 'Welcome to PocketLLM'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_showPasswordField && _emailExists) 
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Your account was found in our system',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_showPasswordField && !_emailExists) 
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Create a new account to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 40),
            if (!_showPasswordField) ...[
              Text(
                'Enter your email to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
                onPressed: _isValidEmail && !_isLoading
                    ? _handleEmailCheck
                    : null,
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
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
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
                        ? () {
                            setState(() {
                              _showPasswordField = false;
                              _passwordController.clear();
                              _emailExists = false;
                            });
                          }
                        : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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
              const SizedBox(height: 16),
              TextButton(
                onPressed: !_isLoading 
                  ? () {
                      setState(() {
                        _showSignupFields = true;
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      });
                    }
                  : null,
                child: const Text(
                  'Create a new account instead',
                  style: TextStyle(color: Color(0xFF8B5CF6)),
                ),
              ),
            ],
            if (_showSignupFields) ...[
              Text(
                _emailController.text,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Create Password',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: !_isLoading 
                        ? () {
                            setState(() {
                              _showPasswordField = false;
                              _showSignupFields = false;
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                              _emailExists = false;
                            });
                          }
                        : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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
                  Expanded(child: Divider(color: Colors.grey[300] ?? Colors.white)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: Colors.grey[600] ?? Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300] ?? Colors.white)),
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
                icon: Image.asset(
                  'assets/google.png',
                  height: 24,
                ),
                label: Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300] ?? Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
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
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: content,
      );
    } else {
      return content;
    }
  }
}