import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'error_service.dart';
import 'network_service.dart';

enum InitializationStatus {
  notStarted,
  inProgress,
  completed,
  failed,
}

class ServiceInitializationResult {
  final String serviceName;
  final bool success;
  final String? error;
  final Duration initializationTime;
  
  ServiceInitializationResult({
    required this.serviceName,
    required this.success,
    this.error,
    required this.initializationTime,
  });
}

class AppLifecycleService extends ChangeNotifier with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();
  
  final ErrorService _errorService = ErrorService();
  
  InitializationStatus _initializationStatus = InitializationStatus.notStarted;
  AppLifecycleState _currentState = AppLifecycleState.detached;
  final List<ServiceInitializationResult> _initializationResults = [];
  final Map<String, dynamic> _serviceInstances = {};
  
  // Getters
  InitializationStatus get initializationStatus => _initializationStatus;
  AppLifecycleState get currentState => _currentState;
  List<ServiceInitializationResult> get initializationResults => 
      List.unmodifiable(_initializationResults);
  bool get isInitialized => _initializationStatus == InitializationStatus.completed;
  bool get hasInitializationErrors => _initializationResults.any((r) => !r.success);
  
  // Initialize all app services in the correct order
  Future<bool> initializeApp() async {
    if (_initializationStatus == InitializationStatus.inProgress) {
      return false; // Already initializing
    }
    
    _initializationStatus = InitializationStatus.inProgress;
    _initializationResults.clear();
    notifyListeners();
    
    try {
      // Add lifecycle observer
      WidgetsBinding.instance.addObserver(this);
      
      // Initialize services in dependency order
      final services = [
        ('ErrorService', _initializeErrorService),
        ('NetworkService', _initializeNetworkService),
        ('LocalDBService', _initializeLocalDBService),
        ('ModelState', _initializeModelState),
        ('PocketLLMService', _initializePocketLLMService),
      ];
      
      bool allSuccessful = true;
      
      for (final (serviceName, initializer) in services) {
        final stopwatch = Stopwatch()..start();
        
        try {
          if (kDebugMode) {
            print('Initializing $serviceName...');
          }
          
          final result = await initializer();
          stopwatch.stop();
          
          final initResult = ServiceInitializationResult(
            serviceName: serviceName,
            success: result,
            initializationTime: stopwatch.elapsed,
          );
          
          _initializationResults.add(initResult);
          
          if (!result) {
            allSuccessful = false;
            await _errorService.logError(
              'Failed to initialize $serviceName',
              StackTrace.current,
              type: ErrorType.initialization,
              severity: ErrorSeverity.high,
              context: 'AppLifecycleService.initializeApp',
            );
          } else {
            if (kDebugMode) {
              print('$serviceName initialized successfully in ${stopwatch.elapsedMilliseconds}ms');
            }
          }
        } catch (e, stackTrace) {
          stopwatch.stop();
          allSuccessful = false;
          
          final initResult = ServiceInitializationResult(
            serviceName: serviceName,
            success: false,
            error: e.toString(),
            initializationTime: stopwatch.elapsed,
          );
          
          _initializationResults.add(initResult);
          
          await _errorService.logError(
            'Exception during $serviceName initialization: $e',
            stackTrace,
            type: ErrorType.initialization,
            severity: ErrorSeverity.critical,
            context: 'AppLifecycleService.initializeApp',
          );
        }
      }
      
      _initializationStatus = allSuccessful 
          ? InitializationStatus.completed 
          : InitializationStatus.failed;
      
      notifyListeners();
      
      if (kDebugMode) {
        final totalTime = _initializationResults
            .map((r) => r.initializationTime.inMilliseconds)
            .reduce((a, b) => a + b);
        print('App initialization ${allSuccessful ? 'completed' : 'failed'} in ${totalTime}ms');
      }
      
      return allSuccessful;
    } catch (e, stackTrace) {
      _initializationStatus = InitializationStatus.failed;
      notifyListeners();
      
      await _errorService.logError(
        'Critical error during app initialization: $e',
        stackTrace,
        type: ErrorType.initialization,
        severity: ErrorSeverity.critical,
        context: 'AppLifecycleService.initializeApp',
      );
      
      return false;
    }
  }
  
  // Initialize individual services
  Future<bool> _initializeErrorService() async {
    try {
      // ErrorService is already a singleton and doesn't need explicit initialization
      _serviceInstances['ErrorService'] = _errorService;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _initializeNetworkService() async {
    try {
      final networkService = NetworkService();
      await networkService.initialize();
      _serviceInstances['NetworkService'] = networkService;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _initializeLocalDBService() async {
    try {
      // We'll handle this initialization in main.dart to avoid circular imports
      // For now, just mark as successful
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _initializeModelState() async {
    try {
      // We'll handle this initialization in main.dart to avoid circular imports
      // For now, just mark as successful
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _initializePocketLLMService() async {
    try {
      // We'll handle this initialization in main.dart to avoid circular imports
      // For now, just mark as successful
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get initialized service instance
  T? getService<T>(String serviceName) {
    return _serviceInstances[serviceName] as T?;
  }
  
  // App lifecycle management
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previousState = _currentState;
    
    switch (state) {
      case AppLifecycleState.resumed:
        _currentState = AppLifecycleState.resumed;
        _onAppResumed();
        break;
      case AppLifecycleState.inactive:
        _currentState = AppLifecycleState.inactive;
        _onAppInactive();
        break;
      case AppLifecycleState.paused:
        _currentState = AppLifecycleState.paused;
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _currentState = AppLifecycleState.detached;
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        _currentState = AppLifecycleState.hidden;
        _onAppHidden();
        break;
    }
    
    if (previousState != _currentState) {
      if (kDebugMode) {
        print('App lifecycle state changed: $previousState -> $_currentState');
      }
      
      _errorService.logError(
        'App lifecycle state changed to $_currentState',
        null,
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        context: 'AppLifecycleService.didChangeAppLifecycleState',
      );
      
      notifyListeners();
    }
  }
  
  // Lifecycle event handlers
  void _onAppResumed() {
    // App came to foreground
    // Refresh network status, sync data, etc.
    final networkService = _serviceInstances['NetworkService'] as NetworkService?;
    networkService?.initialize(); // Re-check connectivity
  }
  
  void _onAppInactive() {
    // App is inactive but still visible (e.g., during phone call)
    // Pause non-critical operations
  }
  
  void _onAppPaused() {
    // App went to background
    // Save state, pause operations, etc.
    _saveAppState();
  }
  
  void _onAppDetached() {
    // App is being terminated
    // Final cleanup
    _performFinalCleanup();
  }
  
  void _onAppHidden() {
    // App is hidden (iOS specific)
    // Similar to paused
    _saveAppState();
  }
  
  // Save app state when going to background
  void _saveAppState() {
    try {
      // Save critical app state
      if (kDebugMode) {
        print('Saving app state...');
      }
      
      // This would typically save current conversation, settings, etc.
      // Implementation depends on specific app requirements
    } catch (e, stackTrace) {
      _errorService.logError(
        'Failed to save app state: $e',
        stackTrace,
        type: ErrorType.storage,
        context: 'AppLifecycleService._saveAppState',
      );
    }
  }
  
  // Perform final cleanup when app is terminating
  void _performFinalCleanup() {
    try {
      if (kDebugMode) {
        print('Performing final cleanup...');
      }
      
      // Dispose services
      final networkService = _serviceInstances['NetworkService'] as NetworkService?;
      networkService?.dispose();
      
      // Remove lifecycle observer
      WidgetsBinding.instance.removeObserver(this);
    } catch (e, stackTrace) {
      _errorService.logError(
        'Error during final cleanup: $e',
        stackTrace,
        type: ErrorType.unknown,
        context: 'AppLifecycleService._performFinalCleanup',
      );
    }
  }
  
  // Restart app initialization (for recovery scenarios)
  Future<bool> restartInitialization() async {
    if (_initializationStatus == InitializationStatus.inProgress) {
      return false;
    }
    
    if (kDebugMode) {
      print('Restarting app initialization...');
    }
    
    // Clear previous results
    _initializationResults.clear();
    _serviceInstances.clear();
    
    return await initializeApp();
  }
  
  // Get initialization summary
  Map<String, dynamic> getInitializationSummary() {
    return {
      'status': _initializationStatus.toString(),
      'totalServices': _initializationResults.length,
      'successfulServices': _initializationResults.where((r) => r.success).length,
      'failedServices': _initializationResults.where((r) => !r.success).length,
      'totalInitializationTime': _initializationResults
          .map((r) => r.initializationTime.inMilliseconds)
          .fold(0, (a, b) => a + b),
      'results': _initializationResults.map((r) => {
        'service': r.serviceName,
        'success': r.success,
        'error': r.error,
        'timeMs': r.initializationTime.inMilliseconds,
      }).toList(),
    };
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}