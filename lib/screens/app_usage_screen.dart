import 'package:flutter/material.dart';
import '../services/app_usage_service.dart';
import '../theme/app_theme.dart';
import 'package:android_intent_plus/android_intent.dart';

class AppUsageScreen extends StatefulWidget {
  const AppUsageScreen({super.key});

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> {
  final AppUsageService _usageService = AppUsageService();
  List<Map<String, dynamic>> _usageData = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    try {
      final data = await _usageService.getAppUsage();
      if (mounted) {
        setState(() {
          _usageData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load usage stats. Please ensure "Usage Access" permission is granted.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Power Consumption'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.warning),
                        const SizedBox(height: 16),
                        Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadUsage,
                          icon: const Icon(Icons.settings),
                          label: const Text('Grant Permission'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => _showRestrictedSettingsHelp(context),
                          icon: const Icon(Icons.help_outline, color: AppTheme.warning),
                          label: const Text('Permission Greyed Out?', style: TextStyle(color: AppTheme.warning)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _usageData.length,
                  itemBuilder: (context, index) {
                    final app = _usageData[index];
                    final usageMinutes = app['usage'] as int;
                    return Card(
                      color: AppTheme.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.android, color: AppTheme.primary),
                        ),
                        title: Text(
                          app['appName'] ?? 'Unknown App',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          '${usageMinutes}m active time',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(usageMinutes / 60).toStringAsFixed(1)}h',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.power_settings_new, color: AppTheme.warning),
                              tooltip: 'Shut Down (Force Stop)',
                              onPressed: () {
                                if (app['packageName'] != null) {
                                  AndroidIntent(
                                    action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
                                    data: 'package:${app['packageName']}',
                                  ).launch();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showRestrictedSettingsHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Android Restricted Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Since this app was installed manually (sideloaded), Android blocks sensitive permissions by default for security.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            const Text(
              'To Fix This:',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent),
            ),
            const SizedBox(height: 12),
            _buildStep(1, 'Go to Settings > Apps > Angry Battery (App Info).'),
            _buildStep(2, 'Tap the 3 dots in the top-right corner.'),
            _buildStep(3, 'Select "Allow restricted settings".'),
            _buildStep(4, 'Come back here and tap "Grant Permission".'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  AndroidIntent(
                    action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
                    data: 'package:com.angrybattery.angry_battery', // Ensure this matches android/app/build.gradle
                  ).launch();
                },
                child: const Text('Open App Info Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
