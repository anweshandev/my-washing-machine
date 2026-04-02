import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TtsService _tts = TtsService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;
    final user = auth.user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Account card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Icon(Icons.person, size: 28, color: cs.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.subtextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Appearance
        Card(
          child: Column(
            children: [
              _SectionHeader(title: 'Appearance'),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: Text(
                  theme.isDark ? 'Dark theme enabled' : 'Light theme enabled',
                ),
                secondary: Icon(
                  theme.isDark ? Icons.dark_mode : Icons.light_mode,
                  color: cs.primary,
                ),
                value: theme.isDark,
                onChanged: (_) => theme.toggle(),
              ),
              SwitchListTile(
                title: const Text('Voice Alerts'),
                subtitle: Text(
                  _tts.enabled
                      ? 'Errors and cues will be spoken'
                      : 'Voice alerts disabled',
                ),
                secondary: Icon(Icons.record_voice_over, color: cs.primary),
                value: _tts.enabled,
                onChanged: (v) => setState(() => _tts.enabled = v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // About
        Card(
          child: Column(
            children: [
              _SectionHeader(title: 'About'),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) {
                  final version = snap.data?.version ?? '...';
                  final build = snap.data?.buildNumber ?? '';
                  return ListTile(
                    leading: Icon(Icons.info_outline, color: cs.primary),
                    title: const Text('Version'),
                    subtitle: Text(
                      '$version${build.isNotEmpty ? ' ($build)' : ''}',
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.gavel, color: cs.primary),
                title: const Text('Licenses'),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'LaundryIQ',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Sign out
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().signOut();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
