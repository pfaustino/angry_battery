import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vampire_service.dart';
import '../theme/app_theme.dart';

class TrustedAppsManagementScreen extends StatelessWidget {
  const TrustedAppsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Trusted Apps'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<VampireService>(
        builder: (context, vampire, child) {
          final trusted = vampire.trustedPackages;
          
          if (trusted.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.shield_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.2)),
                   const SizedBox(height: 16),
                   const Text(
                     "No trusted apps yet.",
                     style: TextStyle(color: AppTheme.textMuted),
                   ),
                   const SizedBox(height: 8),
                   const Padding(
                     padding: EdgeInsets.symmetric(horizontal: 40),
                     child: Text(
                       "You can trust apps from the Vampire Hunter report to hide them from future alerts.",
                       textAlign: TextAlign.center,
                       style: TextStyle(color: Colors.white38, fontSize: 13),
                     ),
                   ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: trusted.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final package = trusted[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _prettyName(package),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.warning),
                      tooltip: "Remove from Trusted",
                      onPressed: () {
                        vampire.removeTrusted(package);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  String _prettyName(String package) {
    if (package.contains('.')) {
      final parts = package.split('.');
      final last = parts.last;
       return last[0].toUpperCase() + last.substring(1);
    }
    return package;
  }
}
