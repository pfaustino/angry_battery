import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/battery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/stat_card.dart';
import '../widgets/usage_chart.dart';
import 'settings_screen.dart';
import 'app_usage_screen.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../services/vampire_service.dart';
import '../widgets/vampire_hunter_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  void _showVampireDialog(VampireAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.nightlight_round, color: AppTheme.warning),
            const SizedBox(width: 8),
            const Text('Vampire Detected! 🧛'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You lost ${alert.drainAmount}% battery while the screen was off (${alert.duration.inMinutes} mins).',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Suspects (Apps running):',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: alert.suspects.isEmpty 
                  ? const Text('Unknown causes.', style: TextStyle(color: Colors.white38))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: alert.suspects.length,
                      itemBuilder: (context, index) {
                        final app = alert.suspects[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          title: Text(app['appName'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                          subtitle: Text('${app['usage']}m active', style: const TextStyle(color: Colors.white38)),
                        );
                      },
                    ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AppUsageScreen()));
            },
            child: const Text('Investigate'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Wait! The Vampires are watching...'),
        content: const Text(
          "Minimizes the app. The service stays alive.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text('Shutdown', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () {
              Navigator.pop(context);
              context.read<BatteryService>().minimizeApp();
            },
            child: const Text('Keep Hunting'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BatteryService>(
      builder: (context, battery, child) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (didPop) return;
            _showExitDialog(context);
          },
          child: Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Angry Battery',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            battery.stateText,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: battery.isCharging 
                                  ? AppTheme.warning 
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.surface,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Battery Indicator
                  Center(
                    child: BatteryIndicator(
                      level: battery.batteryLevel,
                      isCharging: battery.isCharging,
                      size: 220,
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Vampire Hunter Status
                  const VampireHunterCard(),

                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  
                  // Estimated time
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            battery.isCharging 
                                ? Icons.battery_charging_full 
                                : Icons.access_time,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            battery.estimatedTime,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Quick Stats
                  Text(
                    'Quick Stats',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Health',
                          value: battery.health,
                          icon: Icons.favorite,
                          iconColor: battery.health == 'Good' ? AppTheme.primary : AppTheme.accent,
                          subtitle: battery.health == 'Good' ? 'Optimal state' : 'Attention needed',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Temperature',
                          value: battery.useCelsius 
                              ? '${battery.temperature.toStringAsFixed(1)}°C' 
                              : '${(battery.temperature * 9 / 5 + 32).toStringAsFixed(1)}°F',
                          icon: Icons.thermostat,
                          iconColor: battery.temperature > 40 ? AppTheme.accent : AppTheme.warning,
                          subtitle: battery.temperature > 40 ? 'Overheat' : 'Normal',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Screen On',
                          // Format duration: 2h 34m
                          value: '${battery.screenOnTime.inHours}h ${battery.screenOnTime.inMinutes.remainder(60)}m',
                          icon: Icons.phone_android,
                          iconColor: Colors.blueAccent,
                          subtitle: 'Today',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Charge Cycles',
                          value: battery.cycles == -1 ? 'N/A' : '${battery.cycles}',
                          icon: Icons.loop,
                          iconColor: Colors.purpleAccent,
                          subtitle: 'Total',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // App Usage Button
                  _buildActionCard(
                    context,
                    title: 'Analyze App Usage',
                    subtitle: 'Identify power-hungry apps',
                    icon: Icons.analytics_outlined,
                    color: AppTheme.accent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AppUsageScreen()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Usage Chart
                  UsageChart(
                    history: battery.history,
                    height: 220,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Power Saving Tips
                  Text(
                    'Power Saving Tips',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTipCard(
                    context,
                    icon: Icons.brightness_medium,
                    title: 'Reduce Brightness',
                    description: 'Lower screen brightness to save up to 20% battery',
                    color: AppTheme.warning,
                    onTap: () => const AndroidIntent(action: 'android.settings.DISPLAY_SETTINGS').launch(),
                  ),
                  const SizedBox(height: 12),
                  _buildTipCard(
                    context,
                    icon: Icons.wifi_off,
                    title: 'Turn Off Wi-Fi',
                    description: 'Disable Wi-Fi when not in use',
                    color: Colors.blueAccent,
                    onTap: () => const AndroidIntent(action: 'android.settings.WIFI_SETTINGS').launch(),
                  ),
                  const SizedBox(height: 12),
                  _buildTipCard(
                    context,
                    icon: Icons.location_off,
                    title: 'Disable Location',
                    description: 'GPS uses significant battery power',
                    color: AppTheme.accent,
                    onTap: () => const AndroidIntent(action: 'android.settings.LOCATION_SOURCE_SETTINGS').launch(),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }
  
  Widget _buildTipCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
    }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
