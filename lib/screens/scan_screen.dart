import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/washing_machine_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WashingMachineProvider>().loadPairedDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WashingMachineProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Connect to Washer'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection status banner
          if (provider.connectionState == BtConnectionState.connecting)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Connecting...',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          // Paired devices section
          _sectionHeader(
            'Paired Devices',
            trailing: IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => provider.loadPairedDevices(),
            ),
          ),
          if (provider.pairedDevices.isEmpty)
            _emptyCard('No paired Bluetooth devices found')
          else
            ...provider.pairedDevices.map((d) => _deviceTile(d, provider)),

          const SizedBox(height: 24),

          // Discovered devices section
          _sectionHeader(
            'Discovered Devices',
            trailing: provider.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.search, size: 20),
                    onPressed: () => provider.startScan(),
                  ),
          ),
          if (provider.discoveredDevices.isEmpty)
            _emptyCard(
              provider.isScanning
                  ? 'Scanning for devices...'
                  : 'Tap search to discover nearby devices',
            )
          else
            ...provider.discoveredDevices.map((d) => _deviceTile(d, provider)),

          const SizedBox(height: 24),

          // Scan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.isScanning
                  ? null
                  : () => provider.startScan(),
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(provider.isScanning ? 'Scanning...' : 'Start Scan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(msg, style: TextStyle(color: Colors.grey[500])),
        ),
      ),
    );
  }

  Widget _deviceTile(BtDevice device, WashingMachineProvider provider) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.bluetooth, color: Colors.blue),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          device.address,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing:
            provider.connectionState == BtConnectionState.connecting &&
                provider.connectedDeviceName == device.name
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: () async {
          await provider.connectToDevice(device);
          // Listen for connection state to navigate
          _waitForConnection(provider);
        },
      ),
    );
  }

  void _waitForConnection(WashingMachineProvider provider) {
    // Poll connection state briefly
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (provider.connectionState == BtConnectionState.connected) {
        timer.cancel();
        // Auto-authenticate and go to dashboard
        provider.authenticate();
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else if (provider.connectionState == BtConnectionState.disconnected) {
        timer.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed. Try again.')),
        );
      }
    });
  }
}
