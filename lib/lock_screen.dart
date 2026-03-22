import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  late Box settingsBox;
  String _error = '';

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settingsBox');
  }

  void _checkPin() {
    final storedPin = settingsBox.get('pinCode', defaultValue: '1234');
    if (_pinController.text == storedPin) {
      _pinController.clear();
      setState(() => _error = '');
      widget.onUnlocked();
    } else {
      setState(() => _error = 'Incorrect PIN');
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: scheme.primary),
              const SizedBox(height: 24),
              Text(
                'Enter PIN',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: TextStyle(color: scheme.onSurface, fontSize: 20),
                decoration: InputDecoration(
                  hintText: 'PIN',
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                  errorText: _error.isEmpty ? null : _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Unlock',
                  style: TextStyle(fontSize: 18, color: scheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
