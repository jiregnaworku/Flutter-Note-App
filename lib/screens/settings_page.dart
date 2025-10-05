// lib/screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _lockEnabled = false;
  final TextEditingController _pinController = TextEditingController();

  late final Box settingsBox;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settingsBox');
    _lockEnabled = settingsBox.get('lockEnabled', defaultValue: false);
  }

  void _toggleLock(bool value) async {
    if (value) {
      // Ask user to set PIN
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
                  settingsBox.put('pinCode', pin); // Key must match LockScreen
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
      settingsBox.delete('pinCode'); // Key must match LockScreen
      setState(() => _lockEnabled = false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text(
                "App Lock",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              subtitle: const Text(
                "Lock app with a 4-digit PIN",
                style: TextStyle(color: Colors.white70),
              ),
              value: _lockEnabled,
              onChanged: _toggleLock,
              activeThumbColor: Colors.orangeAccent,
            ),
          ],
        ),
      ),
    );
  }
}
