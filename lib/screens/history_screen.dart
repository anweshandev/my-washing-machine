import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/ai_provider.dart';
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
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dateKey = grouped.keys.elementAt(index);
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cs.primary.withValues(alpha: 0.12),
          child: Icon(Icons.local_laundry_service, color: cs.primary, size: 22),
        ),
        title: Text(
          program,
          style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
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
        trailing: Text(
          DateFormat('HH:mm').format(date),
          style: TextStyle(fontSize: 12, color: AppTheme.subtextColor(context)),
        ),
      ),
    );
  }
}
