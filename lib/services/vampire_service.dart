import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_usage_service.dart';

class VampireService {
  static final VampireService _instance = VampireService._internal();
  factory VampireService() => _instance;
  VampireService._internal();

  final Battery _battery = Battery();
  final AppUsageService _usageService = AppUsageService();
  
  static const _eventChannel = EventChannel('com.angrybattery.app/screen_state');
  StreamSubscription? _screenSubscription;
  
  // Settings
  int _thresholdMinutes = 30;
  
  // Monitoring State
  DateTime? _screenOffTime;
  int? _screenOffLevel;
  
  // Alert Callback
  Function(VampireAlert)? onVampireDetected;

  Future<void> start() async {
    await _loadSettings();
    _screenSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event == 'SCREEN_OFF') {
        _onScreenOff();
      } else if (event == 'SCREEN_ON') {
        _onScreenOn();
      }
    });
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _thresholdMinutes = prefs.getInt('vampire_threshold') ?? 30;
  }
  
  Future<void> setThreshold(int minutes) async {
    _thresholdMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('vampire_threshold', minutes);
  }
  
  int get threshold => _thresholdMinutes;

  Future<void> _onScreenOff() async {
    _screenOffTime = DateTime.now();
    _screenOffLevel = await _battery.batteryLevel;
    debugPrint("🧛 Vampire Hunter: Screen OFF at $_screenOffLevel%");
  }

  Future<void> _onScreenOn() async {
    if (_screenOffTime == null || _screenOffLevel == null) return;

    final now = DateTime.now();
    final currentLevel = await _battery.batteryLevel;
    
    final duration = now.difference(_screenOffTime!);
    final drain = _screenOffLevel! - currentLevel;
    
    debugPrint("🧛 Vampire Hunter: Screen ON. Drain: $drain% in ${duration.inMinutes} mins");

    // Thresholds: Drain > 2% AND Duration > _thresholdMinutes
    if (drain >= 2 && duration.inMinutes >= _thresholdMinutes) { 
      // Capture the suspects immediately
      final suspects = await _usageService.getAppUsageForRange(_screenOffTime!, now);
      
      if (onVampireDetected != null) {
        onVampireDetected!(VampireAlert(
          drainAmount: drain,
          duration: duration,
          suspects: suspects,
        ));
      }
    }
    
    // Reset
    _screenOffTime = null;
    _screenOffLevel = null;
  }
  
  void dispose() {
    _screenSubscription?.cancel();
  }
}

class VampireAlert {
  final int drainAmount;
  final Duration duration;
  final List<Map<String, dynamic>> suspects;

  VampireAlert({required this.drainAmount, required this.duration, required this.suspects});
}
