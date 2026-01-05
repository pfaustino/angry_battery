import 'package:flutter/material.dart';
import '../theme/app_theme.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _lowBatteryAlert = true;
  bool _fullChargeAlert = false;
  bool _temperatureAlert = true;
  double _lowBatteryThreshold = 20.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Notifications'),
            _buildSwitchTile(
              'Enable Notifications',
              'Allow the app to send you alerts',
              _notificationsEnabled,
              (val) => setState(() => _notificationsEnabled = val),
            ),
            
            if (_notificationsEnabled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildToggleItem(
                      'Low Battery Alert',
                      _lowBatteryAlert,
                      (val) => setState(() => _lowBatteryAlert = val),
                    ),
                    if (_lowBatteryAlert) ...[
                      const Divider(color: AppTheme.border, height: 24),
                      Row(
                        children: [
                          Text(
                            'Alert at',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Expanded(
                            child: Slider(
                              value: _lowBatteryThreshold,
                              min: 5,
                              max: 50,
                              divisions: 9,
                              activeColor: AppTheme.warning,
                              label: '${_lowBatteryThreshold.round()}%',
                              onChanged: (val) => setState(() => _lowBatteryThreshold = val),
                            ),
                          ),
                          Text(
                            '${_lowBatteryThreshold.round()}%',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ],
                    const Divider(color: AppTheme.border, height: 24),
                    _buildToggleItem(
                      'Full Charge Alert',
                      _fullChargeAlert,
                      (val) => setState(() => _fullChargeAlert = val),
                    ),
                    const Divider(color: AppTheme.border, height: 24),
                    _buildToggleItem(
                      'High Temp Alert',
                      _temperatureAlert,
                      (val) => setState(() => _temperatureAlert = val),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            _buildSectionHeader('Appearance'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dark_mode, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 16),
                      Text(
                        'Dark Mode',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  Text(
                    'Always On',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('About'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.battery_charging_full, size: 48, color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Angry Battery',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Crafted with anger and love.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.all(AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.all(AppTheme.warning),
        ),
      ],
    );
  }
}
