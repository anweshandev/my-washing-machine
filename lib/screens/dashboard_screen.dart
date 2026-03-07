import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/washing_machine_provider.dart';
import '../models/washing_data.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WashingMachineProvider>();
    final telemetry = provider.telemetry;
    final isConnected = provider.connectionState == BtConnectionState.connected;
    final isAuth = provider.isAuthenticated;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(provider.connectedDeviceName ?? 'Washing Machine'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.circle,
              size: 12,
              color: isConnected
                  ? (isAuth ? Colors.green : Colors.orange)
                  : Colors.red,
            ),
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
          // ─── Status Card ───
          _StatusCard(telemetry: telemetry, isAuth: isAuth),
          const SizedBox(height: 16),

          // ─── Program Selection ───
          _ProgramSelector(provider: provider),
          const SizedBox(height: 16),

          // ─── Program Options ───
          _ProgramOptions(provider: provider),
          const SizedBox(height: 16),

          // ─── Control Buttons ───
          _ControlButtons(provider: provider),
          const SizedBox(height: 16),

          // ─── Log ───
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
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      ? Colors.blue
                      : telemetry.isCompleted
                      ? Colors.green
                      : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        telemetry.processName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isAuth)
                        const Text(
                          'Not authenticated',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (telemetry.isRunning)
                  Text(
                    telemetry.remainingTime,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
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
                  _miniStat('Temp', '${telemetry.temperature}°C'),
                  _miniStat('Spin', '${telemetry.spinSpeed} RPM'),
                  _miniStat('Child Lock', telemetry.childLock ? 'ON' : 'OFF'),
                  _miniStat('Door', telemetry.doorLock ? 'Locked' : 'Unlocked'),
                ],
              ),
            ],
            if (telemetry.hasError) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        telemetry.error,
                        style: const TextStyle(
                          color: Colors.red,
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

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Program',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  selectedColor: Colors.blue.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? Colors.blue[800] : Colors.black87,
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
    final prog = provider.selectedProgram;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Temperature
            if (prog.temperatures.isNotEmpty) ...[
              _label('Temperature'),
              Wrap(
                spacing: 8,
                children: prog.temperatures.map((t) {
                  final sel = t == provider.temperature;
                  return ChoiceChip(
                    label: Text(t == 0 ? 'Cold' : '$t°C'),
                    selected: sel,
                    onSelected: (_) => provider.setTemperature(t),
                    selectedColor: Colors.orange.withValues(alpha: 0.2),
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
              _label('Spin Speed'),
              Wrap(
                spacing: 8,
                children: prog.spinSpeeds.map((s) {
                  final sel = s == provider.spinSpeed;
                  return ChoiceChip(
                    label: Text(s == 0 ? 'No Spin' : '$s RPM'),
                    selected: sel,
                    onSelected: (_) => provider.setSpinSpeed(s),
                    selectedColor: Colors.purple.withValues(alpha: 0.2),
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
              _label('Extra Rinse'),
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
            _label('Delay Start (hours)'),
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
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
    final isRunning = provider.telemetry.isRunning;
    final isPaused = provider.telemetry.isPaused;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controls',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Main actions row
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    label: 'Load Program',
                    icon: Icons.upload,
                    color: Colors.blue,
                    onPressed: () => provider.loadAndStartProgram(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    label: isRunning ? 'Pause' : 'Start',
                    icon: isRunning ? Icons.pause : Icons.play_arrow,
                    color: isRunning ? Colors.orange : Colors.green,
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
                    label: 'Cancel',
                    icon: Icons.cancel,
                    color: Colors.red,
                    onPressed: () => _confirmCancel(context, provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    label: 'New Program',
                    icon: Icons.refresh,
                    color: Colors.teal,
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
                    label: provider.telemetry.childLock
                        ? 'Unlock Child'
                        : 'Child Lock',
                    icon: provider.telemetry.childLock
                        ? Icons.lock_open
                        : Icons.lock,
                    color: Colors.deepPurple,
                    onPressed: () => provider.telemetry.childLock
                        ? provider.childLockOff()
                        : provider.childLockOn(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    label: 'Read Status',
                    icon: Icons.sync,
                    color: Colors.indigo,
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
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
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
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Log',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: log.length,
                itemBuilder: (_, i) => Text(
                  log[i],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF00FF00),
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
