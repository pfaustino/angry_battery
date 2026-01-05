import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vampire_service.dart';
import '../theme/app_theme.dart';

class VampireHunterCard extends StatelessWidget {
  const VampireHunterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VampireService>(
      builder: (context, vampire, child) {
        final alert = vampire.lastAlert;
        final hasCatch = alert != null;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasCatch 
                  ? [AppTheme.accent.withOpacity(0.2), AppTheme.accent.withOpacity(0.05)]
                  : [AppTheme.primary.withOpacity(0.2), AppTheme.primary.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasCatch ? AppTheme.accent.withOpacity(0.5) : AppTheme.primary.withOpacity(0.5),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (!hasCatch) return;
                
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
                          'Suspects:',
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
                    ],
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasCatch ? Icons.nightlight_round : Icons.shield,
                              color: hasCatch ? AppTheme.accent : AppTheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Vampire Hunter',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (hasCatch ? AppTheme.accent : AppTheme.primary).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            hasCatch ? 'THREAT DETECTED' : 'ACTIVE',
                            style: TextStyle(
                              color: hasCatch ? AppTheme.accent : AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (hasCatch) ...[
                      Text(
                        'Last catch: ${alert.drainAmount}% drain while idle.',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Suspects: ${alert.suspects.isNotEmpty ? alert.suspects.first['appName'] ?? 'Unknown' : 'Unknown'} and others.',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ] else ...[
                      const Text(
                        'Trap is armed. Monitoring for idle drain when screen is off.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
