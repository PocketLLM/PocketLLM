import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Remove Supabase import
import 'component/splash_screen.dart';
import 'component/home_screen.dart';
import 'component/onboarding_screens/onboarding_screen.dart';
// import 'services/auth_service.dart'; // Remove old auth service
import 'services/local_db_service.dart'; // Add local DB service
import 'package:pocketllm/services/pocket_llm_service.dart';
import 'services/model_state.dart';
import 'services/error_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() async {
  // Catch any errors that occur during app initialization
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      // Initialize LocalDBService
      final localDBService = LocalDBService();
      await localDBService.initialize();

      // Initialize API key
      await PocketLLMService.initializeApiKey();
      
      // Initialize model state
      await ModelState().init();
      
      // Run the app
      runApp(MyApp());
    } catch (error, stackTrace) {
      // Log the error
      final errorService = ErrorService();
      await errorService.logError('Initialization error: $error', stackTrace);
      
      // Still run the app, but with a fallback to show an error message if needed
      runApp(MyApp(initializationError: error.toString()));
    }
  }, (error, stackTrace) async {
    // This catches errors that were thrown asynchronously
    final errorService = ErrorService();
    await errorService.logError('Uncaught async error: $error', stackTrace);
  });
}

class MyApp extends StatelessWidget {
  final String? initializationError;
  
  const MyApp({this.initializationError, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketLLM',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: Colors.purple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: initializationError != null
          ? ErrorScreen(error: initializationError!)
          : SplashLoader(),
    );
  }
}

// Simple error screen to show if app initialization fails
class ErrorScreen extends StatelessWidget {
  final String error;
  
  const ErrorScreen({required this.error, Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Initialization Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The app encountered an error during initialization. Please restart the app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Try to restart the app
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SplashLoader()),
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashLoader extends StatefulWidget {
  @override
  _SplashLoaderState createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<SplashLoader> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool showHome = prefs.getBool('showHome') ?? false;
      final localDBService = LocalDBService();

      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      // If the onboarding has been completed, go to home screen
      // Otherwise, go to onboarding screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => showHome ? const HomeScreen() : const OnboardingScreen(),
        ),
      );
    } catch (e, stackTrace) {
      // Log the error
      await ErrorService().logError('Error checking onboarding status: $e', stackTrace);
      
      if (!mounted) return;
      
      // Show a fallback screen with an error message
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ErrorScreen(error: e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      onAnimationComplete: () {},
    );
  }
}
