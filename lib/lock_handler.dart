// lib/lock_handler.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_page.dart';
import 'lock_screen.dart';

class LockHandler extends StatefulWidget {
  const LockHandler({super.key});

  @override
  State<LockHandler> createState() => _LockHandlerState();
}

class _LockHandlerState extends State<LockHandler> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _lockEnabled = false;
  late final Box settingsBox;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Grab the already opened settings box
    settingsBox = Hive.box('settingsBox');
    _lockEnabled = settingsBox.get('lockEnabled', defaultValue: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_lockEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background
      setState(() => _isLocked = true);
    }
  }

  void _unlockApp() {
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    // Lock disabled -> go straight to HomePage
    if (!_lockEnabled) return const HomePage();

    // App is locked -> show LockScreen
    if (_isLocked) return LockScreen(onUnlocked: _unlockApp);

    // Otherwise, show HomePage
    return const HomePage();
  }
}
