import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settingsBox');
    final accentColor = Color(
      settingsBox.get('accentColor', defaultValue: Colors.orangeAccent.value),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 80, color: accentColor),
              const SizedBox(height: 16),
              const Text(
                "Notes App",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Version 1.0.0\n\n"
                "A beautiful and modern note-taking app with Hive for storage and Lottie animations for fun feedback.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: 16),

              const Text(
                "About the Developer",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/jiregna.jpg'),
              ),
              const SizedBox(height: 16),
              const Text(
                "Hi! I'm Jiregna Worku, a passionate developer focused on creating beautiful, functional apps. "
                "This Notes App is one of my projects to showcase smooth UI/UX and modern Flutter techniques.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
