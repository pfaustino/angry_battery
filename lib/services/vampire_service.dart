import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_usage_service.dart';

import 'dart:convert';

class VampireService extends ChangeNotifier {
  static final VampireService _instance = VampireService._internal();
  factory VampireService() => _instance;
  VampireService._internal();

  final Battery _battery = Battery();
  final AppUsageService _usageService = AppUsageService();
  
  static const _eventChannel = EventChannel('com.angrybattery.app/screen_state');
  StreamSubscription? _screenSubscription;
  
  // Settings
  int _thresholdMinutes = 30;
  List<String> _trustedPackages = [];
  
  // Monitoring State
  DateTime? _screenOffTime;
  int? _screenOffLevel;
  
  VampireAlert? _lastAlert;
  VampireAlert? get lastAlert => _lastAlert;
  
  List<String> get trustedPackages => List.unmodifiable(_trustedPackages);

  // Alert Callback (Keeping for backward compat/dialogs, but UI should listen to notifyListeners)
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
    _trustedPackages = prefs.getStringList('vampire_trusted_apps') ?? [];
    
    final alertJson = prefs.getString('last_vampire_alert');
    if (alertJson != null) {
      try {
        final rawAlert = VampireAlert.fromJson(jsonDecode(alertJson));
        // Filter loaded alert
        final filteredSuspects = rawAlert.suspects.where((app) => 
          !_trustedPackages.contains(app['packageName']) &&
          app['packageName'] != 'com.angrybattery.angry_battery'
        ).toList();
        
        // Only restore if suspects remain (or if we want to show empty alerts, but typically we care about the suspects)
        _lastAlert = VampireAlert(
          drainAmount: rawAlert.drainAmount,
          duration: rawAlert.duration,
          suspects: filteredSuspects,
          timestamp: rawAlert.timestamp,
        );
      } catch (e) {
        debugPrint("Error loading last alert: $e");
      }
    }
    notifyListeners();
  }
  
  Future<void> setThreshold(int minutes) async {
    _thresholdMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('vampire_threshold', minutes);
    notifyListeners();
  }
  
  Future<void> addTrusted(String packageName) async {
    if (!_trustedPackages.contains(packageName)) {
      _trustedPackages.add(packageName);
      await _saveTrusted();
      
      // Re-filter current alert if it exists
      if (_lastAlert != null) {
        final filtered = _lastAlert!.suspects.where((app) => 
          app['packageName'] != packageName
        ).toList();
        
        _lastAlert = VampireAlert(
          drainAmount: _lastAlert!.drainAmount,
          duration: _lastAlert!.duration,
          suspects: filtered,
          timestamp: _lastAlert!.timestamp,
        );
        _saveAlert(_lastAlert!); 
      }
      notifyListeners();
    }
  }

  Future<void> removeTrusted(String packageName) async {
    if (_trustedPackages.contains(packageName)) {
      _trustedPackages.remove(packageName);
      await _saveTrusted();
      notifyListeners();
    }
  }

  Future<void> _saveTrusted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vampire_trusted_apps', _trustedPackages);
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
      final allSuspects = await _usageService.getAppUsageForRange(_screenOffTime!, now);
      
      // Filter out our own app and trusted apps
      final suspects = allSuspects.where((app) => 
        app['packageName'] != 'com.angrybattery.angry_battery' &&
        !_trustedPackages.contains(app['packageName'])
      ).toList();
      
      final alert = VampireAlert(
        drainAmount: drain,
        duration: duration,
        suspects: suspects,
        timestamp: now,
      );
      
      _lastAlert = alert;
      _saveAlert(alert);
      notifyListeners();

      if (onVampireDetected != null) {
        onVampireDetected!(alert);
      }
    }
    
    // Reset
    _screenOffTime = null;
    _screenOffLevel = null;
  }
  
  Future<void> _saveAlert(VampireAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_vampire_alert', jsonEncode(alert.toJson()));
  }

  void dispose() {
    _screenSubscription?.cancel();
    super.dispose();
  }
}

class VampireAlert {
  final int drainAmount;
  final Duration duration;
  final List<Map<String, dynamic>> suspects;
  final DateTime timestamp;

  VampireAlert({
    required this.drainAmount,
    required this.duration,
    required this.suspects,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'drainAmount': drainAmount,
    'durationMinutes': duration.inMinutes,
    'suspects': suspects,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };
  
  factory VampireAlert.fromJson(Map<String, dynamic> json) => VampireAlert(
    drainAmount: json['drainAmount'],
    duration: Duration(minutes: json['durationMinutes']),
    suspects: List<Map<String, dynamic>>.from(json['suspects']),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
  );
}
