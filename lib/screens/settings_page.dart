import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _lockEnabled = false;
  bool _biometricEnabled = false;
  bool _isDarkMode = true;
  final TextEditingController _pinController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  late final Box settingsBox;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settingsBox');
    _lockEnabled = settingsBox.get('lockEnabled', defaultValue: false);
    _biometricEnabled = settingsBox.get(
      'biometricEnabled',
      defaultValue: false,
    );
    _isDarkMode = settingsBox.get('isDarkMode', defaultValue: true);
  }

  void _toggleLock(bool value) async {
    if (value) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Set 4-digit PIN"),
          content: TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(hintText: "Enter PIN"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final pin = _pinController.text.trim();
                if (pin.length == 4 && int.tryParse(pin) != null) {
                  settingsBox.put('pinCode', pin);
                  settingsBox.put('lockEnabled', true);
                  setState(() => _lockEnabled = true);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN must be 4 digits')),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      );
    } else {
      settingsBox.put('lockEnabled', false);
      settingsBox.put('biometricEnabled', false);
      settingsBox.delete('pinCode');
      setState(() {
        _lockEnabled = false;
        _biometricEnabled = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_lockEnabled) return;

    if (!value) {
      settingsBox.put('biometricEnabled', false);
      setState(() => _biometricEnabled = false);
      return;
    }

    final canAuthenticate =
        await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();
    final enrolled = await _localAuth.getAvailableBiometrics();

    if (!canAuthenticate || enrolled.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No biometrics set up on this device.')),
      );
      return;
    }

    settingsBox.put('biometricEnabled', true);
    setState(() => _biometricEnabled = true);
  }

  void _toggleTheme(bool value) {
    setState(() => _isDarkMode = value);
    settingsBox.put('isDarkMode', value);
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Dark mode'),
              subtitle: const Text('Switch between light and dark theme.'),
              value: _isDarkMode,
              onChanged: _toggleTheme,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('App lock'),
              subtitle: const Text('Lock app with a 4-digit PIN.'),
              value: _lockEnabled,
              onChanged: _toggleLock,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('Biometric unlock'),
              subtitle: const Text(
                'Use fingerprint/face unlock with PIN fallback.',
              ),
              value: _biometricEnabled,
              onChanged: _lockEnabled ? _toggleBiometric : null,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.verified_user_outlined,
                color: scheme.primary,
              ),
              title: const Text('Professional theme system'),
              subtitle: const Text('Custom accent palettes have been removed.'),
            ),
          ),
        ],
      ),
    );
  }
}
