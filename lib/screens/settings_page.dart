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
  Color _accentColor = Colors.orangeAccent;

  final List<Color> availableColors = [
    Colors.orangeAccent,
    Colors.tealAccent,
    Colors.purpleAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.redAccent,
    Colors.amberAccent,
  ];

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settingsBox');
    _lockEnabled = settingsBox.get('lockEnabled', defaultValue: false);
    final savedColorValue = settingsBox.get(
      'accentColor',
      defaultValue: Colors.orangeAccent.value,
    );
    _accentColor = Color(savedColorValue);
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
      settingsBox.delete('pinCode');
      setState(() => _lockEnabled = false);
    }
  }

  void _showColorPicker() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose App Accent Color"),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: availableColors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _accentColor = color;
                  settingsBox.put('accentColor', color.value);
                });
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accentColor == color ? Colors.white : Colors.grey,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
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
            // 🔐 App Lock Setting
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
              activeThumbColor: _accentColor,
            ),

            const Divider(color: Colors.white24),

            // 🎨 Accent Color Setting
            ListTile(
              title: const Text(
                "App Accent Color",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              subtitle: const Text(
                "Customize the color theme",
                style: TextStyle(color: Colors.white70),
              ),
              trailing: CircleAvatar(backgroundColor: _accentColor, radius: 14),
              onTap: _showColorPicker,
            ),
          ],
        ),
      ),
    );
  }
}
