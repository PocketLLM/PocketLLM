/// File Overview:
/// - Purpose: Tracks connectivity status and queues outbound messages while
///   offline.
/// - Backend Migration: Keep but integrate with backend sync signals so queuing
///   semantics align with server expectations.
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'error_service.dart';

enum NetworkStatus {
  online,
  offline,
  unknown
}

enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  none,
  unknown
}

class QueuedMessage {
  final String id;
  final String endpoint;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final Duration retryDelay;
  
  QueuedMessage({
    required this.id,
    required this.endpoint,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.retryDelay = const Duration(seconds: 5),
  });
  
  QueuedMessage copyWith({
    int? retryCount,
    Duration? retryDelay,
  }) {
    return QueuedMessage(
      id: id,
      endpoint: endpoint,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'retryDelayMs': retryDelay.inMilliseconds,
    };
  }
  
  factory QueuedMessage.fromJson(Map<String, dynamic> json) {
    return QueuedMessage(
      id: json['id'],
      endpoint: json['endpoint'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
      retryDelay: Duration(milliseconds: json['retryDelayMs'] ?? 5000),
    );
  }
}

class NetworkService extends ChangeNotifier {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();
  
  final Connectivity _connectivity = Connectivity();
  final ErrorService _errorService = ErrorService();
  
  NetworkStatus _status = NetworkStatus.unknown;
  ConnectionType _connectionType = ConnectionType.unknown;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  final List<QueuedMessage> _messageQueue = [];
  Timer? _retryTimer;
  bool _isProcessingQueue = false;
  
  // Getters
  NetworkStatus get status => _status;
  ConnectionType get connectionType => _connectionType;
  bool get isOnline => _status == NetworkStatus.online;
  bool get isOffline => _status == NetworkStatus.offline;
  List<QueuedMessage> get queuedMessages => List.unmodifiable(_messageQueue);
  int get queuedMessageCount => _messageQueue.length;
  
  // Initialize the network service
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      await _checkConnectivity();
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          _errorService.logError(
            'Connectivity subscription error: $error',
            StackTrace.current,
            type: ErrorType.network,
            context: 'NetworkService.initialize',
          );
        },
      );
      
      // Start processing queued messages if online
      if (isOnline) {
        _startQueueProcessing();
      }
      
      if (kDebugMode) {
        print('NetworkService initialized - Status: $_status, Type: $_connectionType');
      }
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to initialize NetworkService: $e',
        stackTrace,
        type: ErrorType.initialization,
        context: 'NetworkService.initialize',
      );
    }
  }
  
  // Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
  
  // Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      await _updateNetworkStatus(connectivityResults);
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to check connectivity: $e',
        stackTrace,
        type: ErrorType.network,
        context: 'NetworkService._checkConnectivity',
      );
      _updateStatusOffline();
    }
  }
  
  // Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateNetworkStatus(results);
  }
  
  // Update network status based on connectivity results
  Future<void> _updateNetworkStatus(List<ConnectivityResult> results) async {
    final previousStatus = _status;
    
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _updateStatusOffline();
    } else {
      // Determine connection type
      if (results.contains(ConnectivityResult.wifi)) {
        _connectionType = ConnectionType.wifi;
      } else if (results.contains(ConnectivityResult.mobile)) {
        _connectionType = ConnectionType.mobile;
      } else if (results.contains(ConnectivityResult.ethernet)) {
        _connectionType = ConnectionType.ethernet;
      } else {
        _connectionType = ConnectionType.unknown;
      }
      
      // Verify actual internet connectivity
      final hasInternet = await _verifyInternetConnection();
      if (hasInternet) {
        _status = NetworkStatus.online;
        
        // Start processing queued messages when coming back online
        if (previousStatus == NetworkStatus.offline) {
          _startQueueProcessing();
        }
      } else {
        _updateStatusOffline();
      }
    }
    
    // Log status changes
    if (previousStatus != _status) {
      if (kDebugMode) {
        print('Network status changed: $previousStatus -> $_status ($_connectionType)');
      }
      
      await _errorService.logError(
        'Network status changed to $_status via $_connectionType',
        null,
        type: ErrorType.network,
        severity: _status == NetworkStatus.offline ? ErrorSeverity.medium : ErrorSeverity.low,
        context: 'NetworkService._updateNetworkStatus',
      );
    }
    
    notifyListeners();
  }
  
  // Update status to offline
  void _updateStatusOffline() {
    _status = NetworkStatus.offline;
    _connectionType = ConnectionType.none;
    _stopQueueProcessing();
  }
  
  // Verify actual internet connection by attempting to reach a reliable host
  Future<bool> _verifyInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Queue a message for later sending when network is available
  void queueMessage({
    required String id,
    required String endpoint,
    required Map<String, dynamic> data,
  }) {
    final message = QueuedMessage(
      id: id,
      endpoint: endpoint,
      data: data,
      timestamp: DateTime.now(),
    );
    
    _messageQueue.add(message);
    
    if (kDebugMode) {
      print('Message queued: $id (${_messageQueue.length} total)');
    }
    
    notifyListeners();
    
    // Try to process immediately if online
    if (isOnline && !_isProcessingQueue) {
      _startQueueProcessing();
    }
  }
  
  // Remove a message from the queue
  void removeQueuedMessage(String id) {
    _messageQueue.removeWhere((message) => message.id == id);
    notifyListeners();
  }
  
  // Clear all queued messages
  void clearMessageQueue() {
    _messageQueue.clear();
    notifyListeners();
    
    if (kDebugMode) {
      print('Message queue cleared');
    }
  }
  
  // Start processing queued messages
  void _startQueueProcessing() {
    if (_isProcessingQueue || _messageQueue.isEmpty || !isOnline) {
      return;
    }
    
    _isProcessingQueue = true;
    _processMessageQueue();
  }
  
  // Stop processing queued messages
  void _stopQueueProcessing() {
    _retryTimer?.cancel();
    _isProcessingQueue = false;
  }
  
  // Process queued messages
  Future<void> _processMessageQueue() async {
    if (!isOnline || _messageQueue.isEmpty) {
      _isProcessingQueue = false;
      return;
    }
    
    final messagesToProcess = List<QueuedMessage>.from(_messageQueue);
    
    for (final message in messagesToProcess) {
      if (!isOnline) {
        break; // Stop processing if we go offline
      }
      
      try {
        // Attempt to send the message
        final success = await _sendQueuedMessage(message);
        
        if (success) {
          _messageQueue.removeWhere((m) => m.id == message.id);
          if (kDebugMode) {
            print('Successfully sent queued message: ${message.id}');
          }
        } else {
          // Retry logic with exponential backoff
          final updatedMessage = message.copyWith(
            retryCount: message.retryCount + 1,
            retryDelay: Duration(
              milliseconds: (message.retryDelay.inMilliseconds * 1.5).round(),
            ),
          );
          
          final index = _messageQueue.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messageQueue[index] = updatedMessage;
          }
          
          // Remove message if too many retries
          if (updatedMessage.retryCount >= 5) {
            _messageQueue.removeWhere((m) => m.id == message.id);
            await _errorService.logError(
              'Failed to send queued message after 5 retries: ${message.id}',
              null,
              type: ErrorType.network,
              severity: ErrorSeverity.medium,
              context: 'NetworkService._processMessageQueue',
            );
          }
        }
      } catch (e, stackTrace) {
        await _errorService.logError(
          'Error processing queued message ${message.id}: $e',
          stackTrace,
          type: ErrorType.network,
          context: 'NetworkService._processMessageQueue',
        );
      }
    }
    
    notifyListeners();
    
    // Schedule next processing if there are still messages
    if (_messageQueue.isNotEmpty && isOnline) {
      _retryTimer = Timer(const Duration(seconds: 10), () {
        _processMessageQueue();
      });
    } else {
      _isProcessingQueue = false;
    }
  }
  
  // Send a queued message (to be implemented by specific services)
  Future<bool> _sendQueuedMessage(QueuedMessage message) async {
    // This is a placeholder - actual implementation would depend on the specific
    // API or service being used. For now, we'll simulate success/failure.
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Simulate 80% success rate for testing
      return DateTime.now().millisecond % 10 < 8;
    } catch (e) {
      return false;
    }
  }
  
  // Perform network request with automatic retry
  Future<T> performNetworkRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    String? context,
  }) async {
    if (!isOnline) {
      throw NetworkException('No internet connection available');
    }
    
    return await ErrorService.retryWithBackoff(
      request,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
    );
  }
  
  // Check if a specific host is reachable
  Future<bool> isHostReachable(String host, {int port = 80, Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get network information
  Map<String, dynamic> getNetworkInfo() {
    return {
      'status': _status.toString(),
      'connectionType': _connectionType.toString(),
      'isOnline': isOnline,
      'queuedMessages': queuedMessageCount,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;
  final String? code;
  
  NetworkException(this.message, {this.code});
  
  @override
  String toString() => 'NetworkException: $message${code != null ? ' (Code: $code)' : ''}';
}