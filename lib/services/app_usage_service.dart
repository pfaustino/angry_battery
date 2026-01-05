import 'package:flutter/services.dart';

class AppUsageService {
  static const platform = MethodChannel('com.angrybattery.app/battery');

  Future<List<Map<String, dynamic>>> getAppUsage({String duration = 'day'}) async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getBatteryUsage', {'duration': duration});
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } on PlatformException catch (e) {
      print("Failed to get usage stats: '${e.message}'.");
      return [];
    }
  }
}
