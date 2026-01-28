import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'notification_service.dart';

class BatteryService extends ChangeNotifier {
  final Battery _battery = Battery();
  final NotificationService _notifications = NotificationService();
  static const _channel = MethodChannel('com.angrybattery.app/battery');
  
  int _batteryLevel = 0;
  double _temperature = 0.0;
  String _health = 'Unknown';
  int _cycles = -1;
  Duration _screenOnTime = Duration.zero;
  bool _useCelsius = true;
  BatteryState _batteryState = BatteryState.unknown;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _levelTimer;
  
  // Usage history (last 24 data points for the chart)
  final List<BatteryRecord> _history = [];
  
  int get batteryLevel => _batteryLevel;
  double get temperature => _temperature;
  String get health => _health;
  int get cycles => _cycles;
  Duration get screenOnTime => _screenOnTime;
  bool get useCelsius => _useCelsius;
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
    double minutesPerPercent;
    
    if (isCharging) {
      minutesPerPercent = 1.5; // Default: ~1.5 min per percent for charging
    } else {
      minutesPerPercent = 6.0; // Default: ~6 min per percent for discharging (~10h total)
    }

    // Attempt to refine estimation based on recent history
    if (_history.length >= 2) {
      // Find the start of the current contiguous state sequence (charging or discharging)
      int startIndex = _history.length - 1;
      while (startIndex > 0 && _history[startIndex - 1].isCharging == isCharging) {
        startIndex--;
      }
      
      // We need at least 2 records in the current state to compare
      if (startIndex < _history.length - 1) {
        final startRecord = _history[startIndex];
        final endRecord = _history.last;
        
        final int levelDiff = (startRecord.level - endRecord.level).abs();
        final int timeDiff = endRecord.timestamp.difference(startRecord.timestamp).inMinutes;
        
        // Ensure we have observed an actual change in battery level and sufficient time passed (e.g. > 2 mins)
        // to avoid noise (fluctuations without level change).
        if (levelDiff > 0 && timeDiff >= 2) {
           minutesPerPercent = timeDiff / levelDiff;
        }
      }
    }

    int totalMinutes;
    if (isCharging) {
      final remainingLevel = 100 - _batteryLevel;
      totalMinutes = (remainingLevel * minutesPerPercent).round();
      
      if (totalMinutes < 60) return '$totalMinutes min to full';
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      if (mins == 0) return '$hours hr to full';
      return '$hours hr $mins min to full';
    } else {
      // Discharging
      totalMinutes = (_batteryLevel * minutesPerPercent).round();
      
      if (totalMinutes < 60) return '$totalMinutes min remaining';
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      if (mins == 0) return '$hours hr remaining';
      return '$hours hr $mins min remaining';
    }
  }
  
  Future<void> initialize() async {
    // Get initial battery level
    // Get initial battery level with timeout to prevent freeze
    try {
      await _updateBatteryLevel().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint("Initial battery update timed out: $e");
    }
    
    // Listen to battery state changes
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) {
      _batteryState = state;
      // Also check notifications on state change
      _notifications.checkBatteryState(_batteryLevel, isCharging);
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
      try {
        final double temp = await _channel.invokeMethod('getBatteryTemperature');
        _temperature = temp;
        
        final String health = await _channel.invokeMethod('getBatteryHealth');
        _health = health;
        
        final int cycles = await _channel.invokeMethod('getChargeCycles');
        _cycles = cycles;
        
        final int sotMillis = await _channel.invokeMethod('getScreenOnTime');
        _screenOnTime = Duration(milliseconds: sotMillis);
      } on PlatformException catch (e) {
        debugPrint("Failed to get battery stats: '${e.message}'.");
      }
      
      // Triggers shaming if conditions are met
      _notifications.checkBatteryState(_batteryLevel, isCharging);
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting battery level: $e');
    }
  }

  void toggleTemperatureUnit(bool useCelsius) {
    _useCelsius = useCelsius;
    notifyListeners();
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
  
  Future<void> minimizeApp() async {
    try {
      await _channel.invokeMethod('minimizeApp');
    } catch (e) {
      debugPrint("Failed to minimize app: $e");
    }
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
