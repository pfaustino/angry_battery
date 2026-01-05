import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

class BatteryService extends ChangeNotifier {
  final Battery _battery = Battery();
  
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _levelTimer;
  
  // Usage history (last 24 data points for the chart)
  final List<BatteryRecord> _history = [];
  
  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;
  List<BatteryRecord> get history => List.unmodifiable(_history);
  
  bool get isCharging => _batteryState == BatteryState.charging;
  bool get isFull => _batteryState == BatteryState.full;
  bool get isLow => _batteryLevel <= 20;
  bool get isCritical => _batteryLevel <= 10;
  
  String get stateText {
    switch (_batteryState) {
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.discharging:
        return 'Discharging';
      case BatteryState.full:
        return 'Full';
      case BatteryState.connectedNotCharging:
        return 'Connected';
      case BatteryState.unknown:
        return 'Unknown';
    }
  }
  
  String get estimatedTime {
    // Rough estimation based on battery level
    if (isCharging) {
      final remaining = 100 - _batteryLevel;
      final minutes = (remaining * 1.5).round(); // ~1.5 min per percent
      if (minutes < 60) return '$minutes min to full';
      return '${(minutes / 60).round()} hr to full';
    } else {
      final minutes = (_batteryLevel * 6).round(); // ~6 min per percent
      if (minutes < 60) return '$minutes min remaining';
      final hours = minutes / 60;
      return '${hours.toStringAsFixed(1)} hr remaining';
    }
  }
  
  Future<void> initialize() async {
    // Get initial battery level
    await _updateBatteryLevel();
    
    // Listen to battery state changes
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) {
      _batteryState = state;
      notifyListeners();
    });
    
    // Poll battery level every 30 seconds
    _levelTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateBatteryLevel();
    });
    
    // Record initial history point
    _recordHistory();
    
    // Record history every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (_) {
      _recordHistory();
    });
  }
  
  Future<void> _updateBatteryLevel() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting battery level: $e');
    }
  }
  
  void _recordHistory() {
    _history.add(BatteryRecord(
      level: _batteryLevel,
      timestamp: DateTime.now(),
      isCharging: isCharging,
    ));
    
    // Keep only last 24 records (2 hours of data at 5-min intervals)
    if (_history.length > 24) {
      _history.removeAt(0);
    }
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    _levelTimer?.cancel();
    super.dispose();
  }
}

class BatteryRecord {
  final int level;
  final DateTime timestamp;
  final bool isCharging;
  
  BatteryRecord({
    required this.level,
    required this.timestamp,
    required this.isCharging,
  });
}
