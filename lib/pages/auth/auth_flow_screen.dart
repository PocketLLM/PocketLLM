import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../component/home_screen.dart';
import '../../services/auth_state.dart';
import 'auth_page.dart';
import 'user_survey_page.dart';

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({super.key});

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  bool _handledExistingSession = false;

  Future<void> _completeAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authSkipped');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _skipAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('authSkipped', true);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _handleExistingSession(AuthState authState) {
    if (!authState.supabaseAvailable || !authState.isAuthenticated) {
      _handledExistingSession = false;
      return;
    }

    if (_handledExistingSession || authState.profile == null) {
      return;
    }

    _handledExistingSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) {
        return;
      }

      final profile = authState.profile!;
      if (profile.surveyCompleted) {
        _completeAndNavigate();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserSurveyPage(
              onComplete: () => _completeAndNavigate(),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    _handleExistingSession(authState);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: AuthPage(
          showAppBar: false,
          allowSkip: true,
          onSkip: _skipAuthentication,
          onLoginSuccess: (_) => _completeAndNavigate(),
        ),
      ),
    );
  }
}
