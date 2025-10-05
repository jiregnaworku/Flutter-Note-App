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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Enter PIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: InputDecoration(
                  hintText: 'PIN',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  errorText: _error.isEmpty ? null : _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.white12,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Unlock',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
