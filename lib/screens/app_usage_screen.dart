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
                        ElevatedButton(
                          onPressed: _loadUsage,
                          child: const Text('Retry / Grant Permission'),
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
}
