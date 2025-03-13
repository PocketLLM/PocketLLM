import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'component/splash_screen.dart';
import 'component/home_screen.dart';
import 'services/auth_service.dart';
import 'package:pocketllm/services/pocket_llm_service.dart';
import 'services/model_state.dart'; // Add this import

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
      initialRoute: '/',
      routes: {
        '/': (context) => SplashLoader(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

class SplashLoader extends StatefulWidget {
  @override
  _SplashLoaderState createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<SplashLoader> {
  void _onAnimationComplete() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(onAnimationComplete: _onAnimationComplete);
  }
}
