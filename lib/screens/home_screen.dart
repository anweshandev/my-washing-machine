import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/washing_machine_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ai_provider.dart';
import '../models/washing_data.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WashingMachineProvider>();
    final telemetry = provider.telemetry;
    final isConnected = provider.connectionState == BtConnectionState.connected;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.connectedDeviceName ?? 'LaundryIQ'),
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: _ConnectionDot(
            isConnected: isConnected,
            isAuth: provider.isAuthenticated,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
          if (!isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_searching),
              tooltip: 'Connect to device',
              onPressed: () => Navigator.of(context).pushNamed('/scan'),
            ),
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              tooltip: 'Disconnect',
              onPressed: () => provider.disconnect(),
            ),
        ],
      ),
      body: !isConnected
          ? _NotConnectedView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Alert banner
                if (provider.latestAlert != null)
                  _AlertBanner(
                    message: provider.latestAlert!.message,
                    onDismiss: () => provider.dismissAlert(),
                  ),

                // Live status hero card
                _LiveStatusCard(telemetry: telemetry, provider: provider),

                const SizedBox(height: 16),

                // Quick actions when running
                if (telemetry.isRunning || telemetry.isPaused)
                  _RunningControls(provider: provider)
                else ...[
                  // Program selector
                  _ProgramSelector(provider: provider),
                  const SizedBox(height: 16),

                  // Program options
                  _ProgramOptions(provider: provider),
                  const SizedBox(height: 16),

                  // Start section
                  _StartSection(provider: provider),
                ],

                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

// ─── Connection Dot ───
class _ConnectionDot extends StatelessWidget {
  final bool isConnected;
  final bool isAuth;
  const _ConnectionDot({required this.isConnected, required this.isAuth});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isConnected
              ? (isAuth ? Colors.green : Colors.orange)
              : Colors.red.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

// ─── Not Connected View ───
class _NotConnectedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_laundry_service_outlined,
              size: 80,
              color: cs.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Machine Connected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect to your IFB washing machine via Bluetooth to start controlling it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.subtextColor(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/scan'),
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Connect Device'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Alert Banner ───
class _AlertBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _AlertBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: cs.error),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Machine Alert',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.error,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(color: cs.error, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: cs.error, size: 20),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: OutlinedButton.icon(
              onPressed: () {
                final provider = context.read<WashingMachineProvider>();
                final ai = context.read<AiProvider>();
                final telemetry = provider.telemetry;
                ai.explainMachineError(
                  errorName: telemetry.error,
                  errorCode: telemetry.errorCode,
                  processState: telemetry.processName,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: ai,
                      child: const _AiExplainSheet(),
                    ),
                  ),
                );
              },
              icon: Icon(Icons.auto_awesome, size: 14, color: cs.error),
              label: Text(
                'Explain with AI',
                style: TextStyle(fontSize: 12, color: cs.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live Status Card with circular progress ───
class _LiveStatusCard extends StatelessWidget {
  final MachineTelemetry telemetry;
  final WashingMachineProvider provider;
  const _LiveStatusCard({required this.telemetry, required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRunning = telemetry.isRunning;
    final isPaused = telemetry.isPaused;
    final isCompleted = telemetry.isCompleted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Circular progress indicator
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      color: cs.onSurface.withValues(alpha: 0.08),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Progress
                  if (isRunning || isPaused)
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: _estimateProgress(telemetry),
                        strokeWidth: 8,
                        color: isPaused ? cs.tertiary : cs.primary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  if (isCompleted)
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        color: Colors.green,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  // Center content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRunning
                            ? Icons.local_laundry_service
                            : isPaused
                            ? Icons.pause_circle_filled
                            : isCompleted
                            ? Icons.check_circle
                            : Icons.power_settings_new,
                        size: 36,
                        color: isRunning
                            ? cs.primary
                            : isPaused
                            ? cs.tertiary
                            : isCompleted
                            ? Colors.green
                            : cs.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        telemetry.processName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      if (isRunning || isPaused) ...[
                        const SizedBox(height: 4),
                        Text(
                          telemetry.remainingTime,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                            color: isPaused ? cs.tertiary : cs.primary,
                          ),
                        ),
                        Text(
                          'remaining',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status indicators row
            if (isRunning || isPaused || telemetry.temperature > 0) ...[
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(
                    label: 'Temp',
                    value: '${telemetry.temperature}°C',
                    icon: Icons.thermostat,
                  ),
                  _MiniStat(
                    label: 'Spin',
                    value: '${telemetry.spinSpeed}',
                    icon: Icons.speed,
                  ),
                  _MiniStat(
                    label: 'Child Lock',
                    value: telemetry.childLock ? 'ON' : 'OFF',
                    icon: Icons.lock,
                  ),
                  _MiniStat(
                    label: 'Door',
                    value: telemetry.doorLock ? 'Locked' : 'Open',
                    icon: Icons.door_front_door,
                  ),
                ],
              ),
            ],

            // Error display
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

  double _estimateProgress(MachineTelemetry t) {
    // Rough estimation based on process state
    // States: 2=Init, 3=PreWash, 4=MainWash, 5-7=ExtraRinse, 8-10=Rinse, 11=FinalSpin, 12=Anticrease
    if (t.processState <= 2) return 0.05;
    if (t.processState == 3) return 0.10;
    if (t.processState == 4) return 0.30;
    if (t.processState >= 5 && t.processState <= 7) return 0.50;
    if (t.processState >= 8 && t.processState <= 10) return 0.70;
    if (t.processState == 11) return 0.85;
    if (t.processState == 12) return 0.95;
    if (t.processState == 13) return 1.0;
    return 0.5;
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 18, color: cs.primary.withValues(alpha: 0.7)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─── Running Controls (when wash active) ───
class _RunningControls extends StatelessWidget {
  final WashingMachineProvider provider;
  const _RunningControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRunning = provider.telemetry.isRunning;
    final isPaused = provider.telemetry.isPaused;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program info
            Row(
              children: [
                Icon(Icons.local_laundry_service, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  provider.selectedProgram.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isRunning
                        ? () => provider.pauseWash()
                        : isPaused
                        ? () => provider.startWash()
                        : null,
                    icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(isRunning ? 'Pause' : 'Resume'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunning ? cs.secondary : cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmCancel(context),
                    icon: const Icon(Icons.stop),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Child lock toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Child Lock', style: TextStyle(color: cs.onSurface)),
                Switch(
                  value: provider.telemetry.childLock,
                  onChanged: (v) =>
                      v ? provider.childLockOn() : provider.childLockOff(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
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
            child: Text(
              'Cancel Wash',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
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
            Row(
              children: [
                Icon(Icons.tune, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Wash Program',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<AiProvider>(),
                          child: _AiAdvisorShortcut(),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.auto_awesome, size: 16, color: cs.primary),
                  label: Text(
                    'Ask AI',
                    style: TextStyle(fontSize: 12, color: cs.primary),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
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
            Row(
              children: [
                Icon(Icons.settings, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
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

// ─── Start Section ───
class _StartSection extends StatelessWidget {
  final WashingMachineProvider provider;
  const _StartSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Program',
                  style: TextStyle(color: AppTheme.subtextColor(context)),
                ),
                Text(
                  provider.selectedProgram.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Temperature',
                  style: TextStyle(color: AppTheme.subtextColor(context)),
                ),
                Text(
                  provider.temperature == 0
                      ? 'Cold'
                      : '${provider.temperature}°C',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spin Speed',
                  style: TextStyle(color: AppTheme.subtextColor(context)),
                ),
                Text(
                  provider.spinSpeed == 0
                      ? 'No Spin'
                      : '${provider.spinSpeed} RPM',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => provider.loadAndStartProgram(),
                    icon: const Icon(Icons.upload),
                    label: const Text('Load'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.loadAndStartProgram();
                      Future.delayed(
                        const Duration(seconds: 1),
                        () => provider.startWash(),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Wash'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AI Advisor Shortcut (opened from program selector) ───
class _AiAdvisorShortcut extends StatefulWidget {
  @override
  State<_AiAdvisorShortcut> createState() => _AiAdvisorShortcutState();
}

class _AiAdvisorShortcutState extends State<_AiAdvisorShortcut> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<AiProvider>().send(text, feature: AiFeature.washAdvisor);
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Wash Advisor')),
      body: Column(
        children: [
          Expanded(
            child: ai.messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Describe your laundry load and I\'ll recommend the best program.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.subtextColor(context)),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ai.messages.length + (ai.isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == ai.messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      final msg = ai.messages[i];
                      final isUser = msg.role == AiMessageRole.user;
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? cs.primary
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(
                            msg.text,
                            style: TextStyle(
                              color: isUser ? cs.onPrimary : cs.onSurface,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              8 + MediaQuery.of(context).viewPadding.bottom,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 2,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Describe your laundry load...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: ai.isLoading ? null : _send,
                  icon: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Error Explain Sheet (opened from alert banner) ───
class _AiExplainSheet extends StatelessWidget {
  const _AiExplainSheet();

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Error Diagnostics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ai.isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: cs.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing error...',
                      style: TextStyle(color: AppTheme.subtextColor(context)),
                    ),
                  ],
                ),
              )
            : ai.messages.isEmpty
            ? Center(
                child: Text(
                  'No explanation yet.',
                  style: TextStyle(color: AppTheme.subtextColor(context)),
                ),
              )
            : ListView.builder(
                itemCount: ai.messages.length,
                itemBuilder: (context, i) {
                  final msg = ai.messages[i];
                  if (msg.role == AiMessageRole.user) {
                    return const SizedBox.shrink();
                  }
                  return SelectableText(
                    msg.text,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
