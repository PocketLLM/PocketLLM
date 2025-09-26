import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'component/splash_screen.dart';
import 'component/home_screen.dart';
import 'component/onboarding_screens/onboarding_screen.dart';
import 'pages/auth/auth_flow_screen.dart';
import 'package:pocketllm/services/pocket_llm_service.dart';
import 'services/model_state.dart';
import 'services/error_service.dart';
import 'services/app_lifecycle_service.dart';
import 'services/auth_state.dart';
import 'services/theme_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:provider/provider.dart';

// Initialize core services that need to be available before lifecycle service
Future<void> _initializeCoreServices() async {
  try {
    // Initialize API key
    await PocketLLMService.initializeApiKey();

    // Initialize model state
    await ModelState().init();
  } catch (e, stackTrace) {
    final errorService = ErrorService();
    await errorService.logError(
      'Failed to initialize core services: $e',
      stackTrace,
      type: ErrorType.initialization,
      severity: ErrorSeverity.critical,
    );
    rethrow;
  }
}

Widget _buildApp(AppLifecycleService appLifecycleService, {String? initializationError}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthState()),
    ],
    child: MyApp(
      appLifecycleService: appLifecycleService,
      initializationError: initializationError,
    ),
  );
}

void main() async {
  // Catch any errors that occur during app initialization
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await ThemeService().init();

    // Initialize app lifecycle service
    final appLifecycleService = AppLifecycleService();
    
    try {
      // Initialize core services first
      await _initializeCoreServices();
      
      // Initialize all services through the lifecycle service
      final initializationSuccess = await appLifecycleService.initializeApp();
      
      if (initializationSuccess) {
        // Run the app with successful initialization
        runApp(_buildApp(appLifecycleService));
      } else {
        // Run the app with initialization errors
        final summary = appLifecycleService.getInitializationSummary();
        final failedServices = summary['results']
            .where((r) => !r['success'])
            .map((r) => r['service'])
            .join(', ');
        
        runApp(_buildApp(
          appLifecycleService,
          initializationError: 'Failed to initialize services: $failedServices',
        ));
      }
    } catch (error, stackTrace) {
      // Log the error
      final errorService = ErrorService();
      await errorService.logError(
        'Critical initialization error: $error',
        stackTrace,
        type: ErrorType.initialization,
        severity: ErrorSeverity.critical,
      );
      
      // Still run the app, but with a fallback to show an error message
      runApp(_buildApp(
        appLifecycleService,
        initializationError: error.toString(),
      ));
    }
  }, (error, stackTrace) async {
    // This catches errors that were thrown asynchronously
    final errorService = ErrorService();
    await errorService.logError(
      'Uncaught async error: $error',
      stackTrace,
      type: ErrorType.unknown,
      severity: ErrorSeverity.high,
    );
  });
}

class MyApp extends StatelessWidget {
  final AppLifecycleService appLifecycleService;
  final String? initializationError;

  const MyApp({
    required this.appLifecycleService,
    this.initializationError,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, _) {
        final themeService = ThemeService();

        return MaterialApp(
          title: 'PocketLLM',
          theme: themeService.lightTheme,
          darkTheme: themeService.darkTheme,
          themeMode: ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: initializationError != null
              ? ErrorScreen(
                  error: initializationError!,
                  appLifecycleService: appLifecycleService,
                )
              : SplashLoader(appLifecycleService: appLifecycleService),
        );
      },
    );
  }
}

// Enhanced error screen with detailed initialization information
class ErrorScreen extends StatefulWidget {
  final String error;
  final AppLifecycleService appLifecycleService;
  
  const ErrorScreen({
    required this.error,
    required this.appLifecycleService,
    Key? key,
  }) : super(key: key);
  
  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  bool _showDetails = false;
  bool _isRetrying = false;
  
  @override
  Widget build(BuildContext context) {
    final summary = widget.appLifecycleService.getInitializationSummary();
    
    // Check if the error is specifically related to network connectivity
    bool isNetworkError = widget.error.contains('Failed host lookup') || 
                         widget.error.contains('SocketException') ||
                         widget.error.contains('Unable to connect');
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isNetworkError ? Icons.wifi_off : Icons.error_outline, 
                color: isNetworkError ? Colors.orange : Colors.red, 
                size: 64
              ),
              const SizedBox(height: 16),
              Text(
                isNetworkError ? 'Network Connection Required' : 'Initialization Error',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isNetworkError 
                  ? 'Some features require an internet connection. You can still use local models offline.'
                  : 'The app encountered errors during initialization. Some features may not work properly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              
              // Summary information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Services Initialized:'),
                        Text('${summary['successfulServices']}/${summary['totalServices']}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Failed Services:'),
                        Text('${summary['failedServices']}', 
                             style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Additional information about offline mode
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isNetworkError ? Colors.orange[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      isNetworkError ? 'Offline Mode Available' : 'Offline Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isNetworkError ? Colors.orange : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isNetworkError
                        ? 'You can still use PocketLLM with local models like Ollama even when offline. '
                          'Connect to the internet and try again to access remote features.'
                        : 'You can still use PocketLLM with local models. '
                          'Some features may be limited until the initialization issues are resolved.',
                      style: TextStyle(color: isNetworkError ? Colors.orange[800] : Colors.blue[800]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Toggle details button
              TextButton(
                onPressed: () {
                  setState(() {
                    _showDetails = !_showDetails;
                  });
                },
                child: Text(_showDetails ? 'Hide Details' : 'Show Details'),
              ),
              
              // Detailed error information
              if (_showDetails) ...[
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Initialization Details:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...summary['results'].map<Widget>((result) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    result['success'] ? Icons.check_circle : Icons.error,
                                    color: result['success'] ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${result['service']}: ${result['success'] ? 'Success' : result['error'] ?? 'Failed'} (${result['timeMs']}ms)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isRetrying ? null : _retryInitialization,
                      child: _isRetrying 
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Retry Initialization'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Continue with partial initialization
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SplashLoader(
                              appLifecycleService: widget.appLifecycleService,
                            ),
                          ),
                        );
                      },
                      child: const Text('Continue Offline'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _retryInitialization() async {
    setState(() {
      _isRetrying = true;
    });
    
    try {
      final success = await widget.appLifecycleService.restartInitialization();
      
      if (success) {
        // Navigate to splash screen on successful retry
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SplashLoader(
              appLifecycleService: widget.appLifecycleService,
            ),
          ),
        );
      } else {
        // Update the error screen with new information
        setState(() {
          _isRetrying = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retry failed. Some services are still unavailable.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRetrying = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retry failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class SplashLoader extends StatefulWidget {
  final AppLifecycleService appLifecycleService;
  
  const SplashLoader({
    required this.appLifecycleService,
    Key? key,
  }) : super(key: key);
  
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
      // Wait for splash animation
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      // Check if initialization was successful
      if (!widget.appLifecycleService.isInitialized) {
        // Show error screen if initialization failed
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ErrorScreen(
              error: 'App initialization incomplete',
              appLifecycleService: widget.appLifecycleService,
            ),
          ),
        );
        return;
      }

      // Check onboarding status
      final prefs = await SharedPreferences.getInstance();
      final authState = Provider.of<AuthState>(context, listen: false);
      await authState.ready;

      final bool showHome = prefs.getBool('showHome') ?? false;

      Widget destination;
      if (!showHome) {
        destination = const OnboardingScreen();
      } else if (!authState.isServiceAvailable) {
        destination = const HomeScreen();
      } else if (authState.isAuthenticated) {
        destination = const HomeScreen();
      } else {
        final skipped = prefs.getBool('authSkipped') ?? false;
        destination = skipped ? const HomeScreen() : const AuthFlowScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => destination),
      );
    } catch (e, stackTrace) {
      // Log the error
      await ErrorService().logError(
        'Error checking onboarding status: $e',
        stackTrace,
        type: ErrorType.initialization,
        context: 'SplashLoader._checkOnboardingStatus',
      );
      
      if (!mounted) return;
      
      // Show error screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ErrorScreen(
            error: e.toString(),
            appLifecycleService: widget.appLifecycleService,
          ),
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
