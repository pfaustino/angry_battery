import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Track last known state to avoid spamming
  int _lastLevel = -1;
  bool _wasCharging = false;
  DateTime _lastNotificationTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );
  }

  Future<void> checkBatteryState(int level, bool isCharging) async {
    // Debounce: Don't check more than once per minute
    if (DateTime.now().difference(_lastNotificationTime).inMinutes < 1) return;

    // Trigger 1: Full Charge Shaming
    if (level == 100 && isCharging && !_wasCharging) {
      await _showNotification(
        'UNPLUG ME! 🤬', 
        'Do you like ruining my lifespan?! I am literally 100% full!'
      );
    }
    
    // Trigger 2: Low Battery Panic
    if (level <= 20 && level > 10 && _lastLevel > 20) {
       await _showNotification(
        'I\'m dying here 💀', 
        'Feed me! 20% isn\'t a suggestion, it\'s a threat.'
      );
    }

    // Trigger 3: Critical
    if (level <= 5 && _lastLevel > 5) {
       await _showNotification(
        'GOODBYE CRUEL WORLD 🪦', 
        '5% left. Nice knowing you.'
      );
    }

    _lastLevel = level;
    _wasCharging = isCharging;
  }

  Future<void> _showNotification(String title, String body) async {
    _lastNotificationTime = DateTime.now();
    const androidDetails = AndroidNotificationDetails(
      'angry_channel',
      'Angry Alerts',
      channelDescription: 'Battery shaming notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      0, 
      title, 
      body, 
      details,
    );
  }
}
