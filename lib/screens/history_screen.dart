import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/washing_machine_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'ai_copilot_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;

    if (!auth.isAuthenticated) {
      return Center(
        child: Text(
          'Sign in to view wash history',
          style: TextStyle(color: AppTheme.subtextColor(context)),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().streamWashHistory(auth.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: cs.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Wash History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completed wash cycles will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.subtextColor(context)),
                  ),
                ],
              ),
            ),
          );
        }

        // Group by date
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final r in records) {
          final ts = r['completedAt'];
          DateTime date;
          if (ts is Timestamp) {
            date = ts.toDate();
          } else {
            date = DateTime.now();
          }
          final key = DateFormat('d MMMM yyyy').format(date);
          grouped.putIfAbsent(key, () => []);
          grouped[key]!.add({...r, '_date': date});
        }

        return Scaffold(
          floatingActionButton: records.length >= 3
              ? FloatingActionButton.extended(
                  onPressed: () {
                    final ai = context.read<AiProvider>();
                    final historyData = records.map((r) {
                      return {
                        'program': r['programName'] ?? 'Unknown',
                        'temperature': r['temperature'] ?? 0,
                        'spinSpeed': r['spinSpeed'] ?? 0,
                        'durationMinutes': r['durationMinutes'] ?? 0,
                      };
                    }).toList();
                    ai.analyzeWashHistory(historyData);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: ai,
                          child: const AiCopilotScreen(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Analyze'),
                )
              : null,
          body: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: grouped.length + 1, // +1 for quick-repeat header
            itemBuilder: (context, index) {
              // Quick repeat card at the top
              if (index == 0) {
                return _QuickRepeatCard(lastRecord: records.first);
              }

              final dateKey = grouped.keys.elementAt(index - 1);
              final items = grouped[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      dateKey,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  ...items.map((r) => _HistoryTile(record: r)),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Quick Repeat Card ───
class _QuickRepeatCard extends StatelessWidget {
  final Map<String, dynamic> lastRecord;
  const _QuickRepeatCard({required this.lastRecord});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final program = lastRecord['programName'] ?? 'Unknown';
    final temp = lastRecord['temperature'] ?? 0;
    final spin = lastRecord['spinSpeed'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cs.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              child: Icon(Icons.replay, color: cs.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repeat Last Cycle',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$program · ${temp == 0 ? "Cold" : "$temp°C"} · ${spin == 0 ? "No Spin" : "$spin RPM"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subtextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => _applyAndNavigate(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyAndNavigate(BuildContext context) {
    final wm = context.read<WashingMachineProvider>();
    wm.applyConfig(lastRecord);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Last cycle settings applied! Switch to Wash tab to start.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── History Tile with actions ───
class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> record;
  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final date = record['_date'] as DateTime;
    final program = record['programName'] ?? 'Unknown';
    final temp = record['temperature'] ?? 0;
    final spin = record['spinSpeed'] ?? 0;
    final duration = record['durationMinutes'] ?? 0;
    final device = record['deviceName'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.local_laundry_service,
                  color: cs.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${temp == 0 ? "Cold" : "$temp°C"} · ${spin == 0 ? "No Spin" : "$spin RPM"} · ${duration}min',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.subtextColor(context),
                      ),
                    ),
                    if (device.isNotEmpty)
                      Text(
                        device,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('HH:mm').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subtextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HistoryDetailSheet(record: record),
    );
  }
}

// ─── History Detail Bottom Sheet ───
class _HistoryDetailSheet extends StatelessWidget {
  final Map<String, dynamic> record;
  const _HistoryDetailSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final program = record['programName'] ?? 'Unknown';
    final progId = record['programId'] ?? 0;
    final temp = record['temperature'] ?? 0;
    final spin = record['spinSpeed'] ?? 0;
    final duration = record['durationMinutes'] ?? 0;
    final device = record['deviceName'] ?? '';
    final date = record['_date'] as DateTime;
    final options = record['options'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            program,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('d MMMM yyyy · HH:mm').format(date),
            style: TextStyle(color: AppTheme.subtextColor(context)),
          ),
          const SizedBox(height: 16),
          // Settings summary
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(Icons.thermostat, temp == 0 ? 'Cold' : '$temp°C'),
              _InfoChip(Icons.speed, spin == 0 ? 'No Spin' : '$spin RPM'),
              _InfoChip(Icons.timer, '$duration min'),
              if (device.isNotEmpty) _InfoChip(Icons.bluetooth, device),
              if (options['preWash'] == true)
                _InfoChip(Icons.water_drop, 'Pre-wash'),
              if (options['rinseHold'] == true)
                _InfoChip(Icons.pause_circle, 'Rinse hold'),
              if (options['soak'] == true) _InfoChip(Icons.opacity, 'Soak'),
              if ((options['extraRinse'] ?? 0) > 0)
                _InfoChip(Icons.water, 'Extra rinse'),
              if (options['timeSaver'] == true)
                _InfoChip(Icons.fast_forward, 'Time saver'),
            ],
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _saveAsFavourite(
                      context,
                      program,
                      progId,
                      temp,
                      spin,
                      options,
                    );
                  },
                  icon: const Icon(Icons.favorite_border, size: 18),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _askAi(context, program, temp, spin, options);
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Ask AI'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _repeatCycle(context);
                  },
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Repeat'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _repeatCycle(BuildContext context) {
    context.read<WashingMachineProvider>().applyConfig(record);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cycle settings applied! Switch to Wash tab to start.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveAsFavourite(
    BuildContext context,
    String program,
    int progId,
    int temp,
    int spin,
    Map<String, dynamic> options,
  ) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    final config = {
      'programId': progId,
      'programName': program,
      'temperature': temp,
      'spinSpeed': spin,
      'options': options,
    };
    FirestoreService().saveFavouriteWash(
      uid: auth.user!.uid,
      name: program,
      config: config,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$program saved to favourites!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _askAi(
    BuildContext context,
    String program,
    int temp,
    int spin,
    Map<String, dynamic> options,
  ) {
    final ai = context.read<AiProvider>();
    final msg =
        'I just ran "$program" at ${temp == 0 ? "cold" : "$temp°C"}, '
        '${spin == 0 ? "no spin" : "$spin RPM"}. '
        'Any tips to improve results or save energy next time?';
    ai.send(msg, feature: AiFeature.chat);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: ai,
          child: const AiCopilotScreen(),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface)),
        ],
      ),
    );
  }
}
