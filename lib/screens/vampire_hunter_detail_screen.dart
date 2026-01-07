import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../services/vampire_service.dart';
import '../theme/app_theme.dart';

class VampireHunterDetailScreen extends StatefulWidget {
  final VampireAlert alert;

  const VampireHunterDetailScreen({super.key, required this.alert});

  @override
  State<VampireHunterDetailScreen> createState() => _VampireHunterDetailScreenState();
}

class _VampireHunterDetailScreenState extends State<VampireHunterDetailScreen> {
  // Track packages user has visited/checked during this session
  final Set<String> _checkedPackages = {};

  // Local list to allow immediate removal of trusted apps from UI
  late List<Map<String, dynamic>> _suspects;

  @override
  void initState() {
    super.initState();
    _suspects = List.from(widget.alert.suspects);
  }

  void _onTrustPackage(String packageName, String appName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Trust $appName?'),
        content: const Text(
          "Warning, you are about to trust or tolerate this app's battery usage and it will no longer appear on Vampire Hunter.\n\nDon't worry, you can always untrust this in Settings.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () {
              // Add to trusted in service
              context.read<VampireService>().addTrusted(packageName);
              
              // Remove locally
              setState(() {
                _suspects.removeWhere((app) => app['packageName'] == packageName);
              });
              
              Navigator.pop(context); // Close dialog
            },
            child: const Text('Trust'),
          ),
        ],
      ),
    );
  }

  String _cleanAppName(String name) {
    if (name.contains('.') && name.split('.').length > 2) {
      final parts = name.split('.');
      final lastPart = parts.last;
      return lastPart[0].toUpperCase() + lastPart.substring(1);
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Vampire Hunter Report'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.accent.withValues(alpha: 0.2), AppTheme.accent.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.nightlight_round, color: AppTheme.accent, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drain Detected',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.alert.drainAmount}% Battery Lost',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${widget.alert.duration.inMinutes} minutes',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Assessment / Guidance Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.textMuted, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Assessment',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your phone awake for ${_suspects.fold(0, (sum, item) => sum + (item['usage'] as int))} minutes while screen off. Apps listed below were running.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Recommended Action:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'If you were not using these apps, tap to Force Stop. Or tap "Trust" to ignore them.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Suspects',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Suspects List
              if (_suspects.isEmpty)
                Container(
                  padding: const EdgeInsets.all(30),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: AppTheme.accent.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'All suspects cleared or trusted.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              else ...[
                // Top Offender Logic: First in list is top offender since list is sorted by usage
                 if (_suspects.isNotEmpty) ...[
                   _buildSuspectTile(
                      context,
                      _cleanAppName(_suspects.first['appName'] ?? 'Unknown'),
                      _suspects.first['usage'] ?? 0,
                      _suspects.first['packageName'],
                      isTopOffender: true,
                   ),
                   const SizedBox(height: 16),
                ],

                // Rest of the list
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _suspects.length - 1,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final app = _suspects[index + 1];
                    final String appName = _cleanAppName(app['appName'] ?? 'Unknown');
                    final int usage = app['usage'] ?? 0;
                    final String? packageName = app['packageName'];

                    return _buildSuspectTile(context, appName, usage, packageName);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSuspectTile(BuildContext context, String appName, int usage, String? packageName, {bool isTopOffender = false}) {
    final isChecked = packageName != null && _checkedPackages.contains(packageName);

    return Container(
      decoration: BoxDecoration(
        color: isTopOffender 
            ? AppTheme.accent.withValues(alpha: 0.1) 
            : (isChecked ? AppTheme.surface.withOpacity(0.5) : AppTheme.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopOffender ? AppTheme.accent : AppTheme.border,
          width: isTopOffender ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Top Section: Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isChecked 
                        ? Colors.grey.withValues(alpha: 0.1)
                        : (isTopOffender ? AppTheme.accent.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isChecked ? Icons.check_circle : (isTopOffender ? Icons.gpp_bad : Icons.warning_amber_rounded),
                    color: isChecked 
                        ? Colors.grey 
                        : (isTopOffender ? AppTheme.accent : Colors.orange),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Name & Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                         children: [
                           CommonWidgets.flexibleText(
                             appName,
                             style: TextStyle(
                               fontSize: 16,
                               fontWeight: FontWeight.bold,
                               color: isChecked ? Colors.white54 : Colors.white,
                               decoration: isChecked ? TextDecoration.lineThrough : null,
                             ),
                           ),
                           if (isTopOffender && !isChecked) ...[
                             const SizedBox(width: 8),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: AppTheme.accent,
                                 borderRadius: BorderRadius.circular(4),
                               ),
                               child: const Text(
                                 'MAIN SUSPECT',
                                 style: TextStyle(
                                   fontSize: 10,
                                   fontWeight: FontWeight.bold,
                                   color: Colors.black,
                                 ),
                               ),
                             ),
                           ],
                         ],
                      ),
                      Text(
                        '$usage min usage',
                        style: TextStyle(
                          fontSize: 12,
                          color: isChecked ? AppTheme.textMuted : AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: AppTheme.border.withOpacity(0.5)),
          
          // Bottom Section: Action Bar
          Row(
            children: [
              _buildActionButton(
                context,
                icon: isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                label: isChecked ? "Checked" : "Check",
                color: isChecked ? Colors.green : AppTheme.textMuted,
                onTap: packageName != null ? () {
                  setState(() {
                    if (isChecked) {
                      _checkedPackages.remove(packageName);
                    } else {
                      _checkedPackages.add(packageName);
                    }
                  });
                } : null,
              ),
              _buildVerticalDivider(),
              _buildActionButton(
                context,
                icon: Icons.search,
                label: "Search",
                color: AppTheme.textMuted,
                onTap: () async {
                   final query = Uri.encodeComponent('$appName android app');
                   await AndroidIntent(
                     action: 'android.intent.action.VIEW',
                     data: 'https://www.google.com/search?q=$query',
                   ).launch();
                },
              ),
              _buildVerticalDivider(),
              _buildActionButton(
                context,
                icon: Icons.shield_outlined,
                label: "Trust",
                color: AppTheme.textMuted,
                onTap: packageName != null ? () => _onTrustPackage(packageName, appName) : null,
              ),
              _buildVerticalDivider(),
              _buildActionButton(
                context,
                icon: Icons.settings,
                label: "Settings",
                color: isTopOffender ? AppTheme.accent : AppTheme.textMuted,
                isBold: true,
                onTap: packageName != null ? () async {
                  setState(() {
                    _checkedPackages.add(packageName);
                  });
                  await AndroidIntent(
                    action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
                    data: 'package:$packageName',
                  ).launch();
                } : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppTheme.border.withOpacity(0.5),
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isBold = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CommonWidgets {
  static Widget flexibleText(String text, {required TextStyle style}) {
    return Flexible(
      child: Text(
        text,
        style: style,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
