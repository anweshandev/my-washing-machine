import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/washing_machine_provider.dart';
import '../providers/theme_provider.dart';
import '../models/washing_data.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WashingMachineProvider>();
    final telemetry = provider.telemetry;
    final cs = Theme.of(context).colorScheme;
    final isConnected = provider.connectionState == BtConnectionState.connected;
    final isAuth = provider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.connectedDeviceName ?? 'Washing Machine'),
        actions: [
          // Connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.circle,
              size: 12,
              color: isConnected
                  ? (isAuth ? cs.primary : cs.secondary)
                  : cs.error,
            ),
          ),
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Disconnect',
            onPressed: () async {
              await provider.disconnect();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/scan');
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(telemetry: telemetry, isAuth: isAuth),
          const SizedBox(height: 16),
          _ProgramSelector(provider: provider),
          const SizedBox(height: 16),
          _ProgramOptions(provider: provider),
          const SizedBox(height: 16),
          _ControlButtons(provider: provider),
          const SizedBox(height: 16),
          _LogPanel(log: provider.log),
        ],
      ),
    );
  }
}

// ─── Status Card ───
class _StatusCard extends StatelessWidget {
  final MachineTelemetry telemetry;
  final bool isAuth;

  const _StatusCard({required this.telemetry, required this.isAuth});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  telemetry.isRunning
                      ? Icons.local_laundry_service
                      : telemetry.isCompleted
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: telemetry.isRunning
                      ? cs.secondary
                      : telemetry.isCompleted
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.4),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        telemetry.processName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      if (!isAuth)
                        Text(
                          'Not authenticated',
                          style: TextStyle(color: cs.secondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (telemetry.isRunning)
                  Text(
                    telemetry.remainingTime,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Roboto',
                      color: cs.primary,
                    ),
                  ),
              ],
            ),
            if (telemetry.isRunning || telemetry.temperature > 0) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat(context, 'Temp', '${telemetry.temperature}°C'),
                  _miniStat(context, 'Spin', '${telemetry.spinSpeed} RPM'),
                  _miniStat(
                    context,
                    'Child Lock',
                    telemetry.childLock ? 'ON' : 'OFF',
                  ),
                  _miniStat(
                    context,
                    'Door',
                    telemetry.doorLock ? 'Locked' : 'Unlocked',
                  ),
                ],
              ),
            ],
            if (telemetry.hasError) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: cs.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        telemetry.error,
                        style: TextStyle(
                          color: cs.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─── Program Selector ───
class _ProgramSelector extends StatelessWidget {
  final WashingMachineProvider provider;
  const _ProgramSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Program',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WashingData.programs.map((p) {
                final selected = p.id == provider.selectedProgramId;
                return ChoiceChip(
                  label: Text(p.name),
                  selected: selected,
                  onSelected: (_) => provider.selectProgram(p.id),
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? cs.primary : cs.onSurface,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Program Options ───
class _ProgramOptions extends StatelessWidget {
  final WashingMachineProvider provider;
  const _ProgramOptions({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prog = provider.selectedProgram;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Temperature
            if (prog.temperatures.isNotEmpty) ...[
              _label(context, 'Temperature'),
              Wrap(
                spacing: 8,
                children: prog.temperatures.map((t) {
                  final sel = t == provider.temperature;
                  return ChoiceChip(
                    label: Text(t == 0 ? 'Cold' : '$t°C'),
                    selected: sel,
                    onSelected: (_) => provider.setTemperature(t),
                    labelStyle: TextStyle(
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Spin Speed
            if (prog.spinSpeeds.isNotEmpty) ...[
              _label(context, 'Spin Speed'),
              Wrap(
                spacing: 8,
                children: prog.spinSpeeds.map((s) {
                  final sel = s == provider.spinSpeed;
                  return ChoiceChip(
                    label: Text(s == 0 ? 'No Spin' : '$s RPM'),
                    selected: sel,
                    onSelected: (_) => provider.setSpinSpeed(s),
                    labelStyle: TextStyle(
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Toggles
            if (prog.canPreWash)
              SwitchListTile(
                title: const Text('Pre-Wash', style: TextStyle(fontSize: 14)),
                value: provider.preWash,
                onChanged: (v) => provider.setPreWash(v),
                dense: true,
              ),
            if (prog.canRinseHold)
              SwitchListTile(
                title: const Text('Rinse Hold', style: TextStyle(fontSize: 14)),
                value: provider.rinseHold,
                onChanged: (v) => provider.setRinseHold(v),
                dense: true,
              ),
            if (prog.canSoak)
              SwitchListTile(
                title: const Text('Soak', style: TextStyle(fontSize: 14)),
                value: provider.soak,
                onChanged: (v) => provider.setSoak(v),
                dense: true,
              ),
            if (prog.canTimeSaver)
              SwitchListTile(
                title: const Text('Time Saver', style: TextStyle(fontSize: 14)),
                value: provider.timeSaver,
                onChanged: (v) => provider.setTimeSaver(v),
                dense: true,
              ),
            if (prog.canExtraRinse) ...[
              _label(context, 'Extra Rinse'),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Off')),
                  ButtonSegment(value: 1, label: Text('+1')),
                  ButtonSegment(value: 2, label: Text('+2')),
                  ButtonSegment(value: 3, label: Text('+3')),
                ],
                selected: {provider.extraRinse},
                onSelectionChanged: (v) => provider.setExtraRinse(v.first),
              ),
              const SizedBox(height: 8),
            ],

            // Delay start
            _label(context, 'Delay Start (hours)'),
            Slider(
              value: provider.delayStart.toDouble(),
              min: 0,
              max: 24,
              divisions: 24,
              label: provider.delayStart == 0
                  ? 'Off'
                  : '${provider.delayStart}h',
              onChanged: (v) => provider.setDelayStart(v.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    ),
  );
}

// ─── Control Buttons ───
class _ControlButtons extends StatelessWidget {
  final WashingMachineProvider provider;
  const _ControlButtons({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRunning = provider.telemetry.isRunning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controls',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Main actions row
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    context: context,
                    label: 'Load Program',
                    icon: Icons.upload,
                    color: cs.primary,
                    onPressed: () => provider.loadAndStartProgram(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    context: context,
                    label: isRunning ? 'Pause' : 'Start',
                    icon: isRunning ? Icons.pause : Icons.play_arrow,
                    color: isRunning ? cs.secondary : cs.primary,
                    onPressed: () =>
                        isRunning ? provider.pauseWash() : provider.startWash(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    context: context,
                    label: 'Cancel',
                    icon: Icons.cancel,
                    color: cs.error,
                    onPressed: () => _confirmCancel(context, provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    context: context,
                    label: 'New Program',
                    icon: Icons.refresh,
                    color: cs.tertiary,
                    onPressed: () => provider.newProgram(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    context: context,
                    label: provider.telemetry.childLock
                        ? 'Unlock Child'
                        : 'Child Lock',
                    icon: provider.telemetry.childLock
                        ? Icons.lock_open
                        : Icons.lock,
                    color: cs.tertiary,
                    onPressed: () => provider.telemetry.childLock
                        ? provider.childLockOff()
                        : provider.childLockOn(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    context: context,
                    label: 'Read Status',
                    icon: Icons.sync,
                    color: cs.primary,
                    onPressed: () => provider.readAllStatus(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WashingMachineProvider provider) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Wash?'),
        content: const Text(
          'Are you sure you want to cancel the current wash cycle?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.cancelWash();
            },
            child: Text('Yes, Cancel', style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: onColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Log Panel ───
class _LogPanel extends StatelessWidget {
  final List<String> log;
  const _LogPanel({required this.log});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: isDark ? cs.surface : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: log.length,
                itemBuilder: (_, i) => Text(
                  log[i],
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: cs.primary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
