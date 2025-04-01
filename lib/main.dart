import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'component/splash_screen.dart';
import 'component/home_screen.dart';
import 'component/onboarding_screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'package:pocketllm/services/pocket_llm_service.dart';
import 'services/model_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://hlaazlztxxtdvtluxniq.supabase.co', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsYWF6bHp0eHh0ZHZ0bHV4bmlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzNzkzNTQsImV4cCI6MjA1NTk1NTM1NH0.gM33TZdqF9KpidYXOS8Z12XkNkFJHzpzUUKsR_rCcNg', // Replace with your Supabase anon key
  );
  
  // Create an instance of AuthService to restore the session
  final authService = AuthService();
  await authService.restoreSession();

  await PocketLLMService.initializeApiKey(); // Initialize API key
  final apiKey = await PocketLLMService.getApiKey();
  debugPrint('PocketLLM API Key initialized: $apiKey'); // Add this for debugging
  await ModelState().init(); // Initialize the model state

  runApp(MyApp()); // test
}

class MyApp extends StatelessWidget {
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
      home: SplashLoader(),
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
    final prefs = await SharedPreferences.getInstance();
    final bool showHome = prefs.getBool('showHome') ?? false;

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => showHome ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      onAnimationComplete: () {},
    );
  }
}
