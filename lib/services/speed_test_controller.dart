import 'package:flutter/foundation.dart';

import '../models/vpn_models.dart';
import 'speed_test_service.dart';
import 'vpn_connection_service.dart';

enum SpeedTestStatus { idle, running, completed, error }

class SpeedTestController extends ChangeNotifier {
  SpeedTestController({
    required SpeedTestService speedTestService,
    required VpnConnectionService connectionService,
  })  : _speedTestService = speedTestService,
        _connectionService = connectionService;

  final SpeedTestService _speedTestService;
  final VpnConnectionService _connectionService;

  SpeedTestStatus _status = SpeedTestStatus.idle;
  SpeedTestResult? _result;
  String? _errorMessage;
  double _progress = 0;

  SpeedTestStatus get status => _status;
  SpeedTestResult? get result => _result;
  String? get errorMessage => _errorMessage;
  double get progress => _progress;

  bool get isRunning => _status == SpeedTestStatus.running;

  Future<void> start() async {
    if (_status == SpeedTestStatus.running) return;

    _status = SpeedTestStatus.running;
    _progress = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final VpnLocation location = _connectionService.selectedLocation;
      final SpeedTestResult currentResult = await _speedTestService.runTest(
        location: location,
        onProgress: (double value) {
          _progress = value.clamp(0.0, 1.0);
          notifyListeners();
        },
      );

      _status = SpeedTestStatus.completed;
      _result = currentResult;
      _progress = 1.0;

      _connectionService.addSpeedTestResult(currentResult);
      notifyListeners();
    } on SpeedTestException catch (error) {
      _status = SpeedTestStatus.error;
      _errorMessage = error.message;
      _progress = 0;
      notifyListeners();
    } catch (error) {
      _status = SpeedTestStatus.error;
      _errorMessage = 'Unexpected error: $error';
      _progress = 0;
      notifyListeners();
    }
  }

  void reset() {
    if (_status == SpeedTestStatus.running) return;
    _status = SpeedTestStatus.idle;
    _progress = 0;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _speedTestService.dispose();
    super.dispose();
  }
}
