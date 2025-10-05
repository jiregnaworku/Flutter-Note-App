import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_page.dart';
import 'lock_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(NoteAdapter());
  }

  // Open boxes (await them to ensure ready before app starts)
  await Hive.openBox('settingsBox');
  await Hive.openBox<Note>('notesBox');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Box settingsBox;
  late Color accentColor;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settingsBox');
    accentColor = Color(
      settingsBox.get('accentColor', defaultValue: Colors.orangeAccent.value),
    );

    // Listen for color changes dynamically
    settingsBox.watch(key: 'accentColor').listen((event) {
      setState(() {
        accentColor = Color(event.value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Notes App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: accentColor),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accentColor,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(accentColor),
        ),
      ),
      home: const LockHandler(),
    );
  }
}
