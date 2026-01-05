import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/battery_service.dart';
import 'screens/home_screen.dart';


void main() {
  runApp(const AngryBatteryApp());
}

class AngryBatteryApp extends StatelessWidget {
  const AngryBatteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BatteryService()..initialize(),
      child: MaterialApp(
        title: 'Angry Battery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
