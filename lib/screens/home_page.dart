import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import 'note_page.dart';
import 'about_page.dart';
import 'settings_page.dart';

// Hive Note model
part 'home_page.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime createdAt;

  Note({required this.title, required this.content, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final Box<Note> _notesBox;
  final Random _random = Random();
  String _searchQuery = '';

  final List<Color> _cardColors = [
    Colors.purple.shade300,
    Colors.pink.shade300,
    Colors.orange.shade300,
    Colors.teal.shade300,
    Colors.blue.shade300,
  ];

  late final Box settingsBox;
  late Color accentColor;

  @override
  void initState() {
    super.initState();
    _notesBox = Hive.box<Note>('notesBox');
    settingsBox = Hive.box('settingsBox');
    accentColor = Color(
      settingsBox.get('accentColor', defaultValue: Colors.orangeAccent.value),
    );

    // Listen to color changes dynamically
    settingsBox.watch(key: 'accentColor').listen((event) {
      setState(() {
        accentColor = Color(event.value);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Note> get _filteredNotes {
    final allNotes = _notesBox.values.toList();
    if (_searchQuery.isEmpty) return allNotes;
    return allNotes
        .where(
          (note) =>
              note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              note.content.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<void> _deleteNoteAt(int index) async {
    final note = _filteredNotes[index];
    await note.delete();
    setState(() {});
  }

  Future<void> _openNotePage({Note? note}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotePage(note: note)),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notes = _filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      drawer: _buildDrawer(context),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: Text(
                          'No notes yet.',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          final color =
                              _cardColors[_random.nextInt(_cardColors.length)];

                          return Dismissible(
                            key: Key(note.key.toString()),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _deleteNoteAt(index),
                            child: Card(
                              color: color.withOpacity(0.9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                title: Text(
                                  note.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  note.content.length > 80
                                      ? '${note.content.substring(0, 80)}...'
                                      : note.content,
                                ),
                                trailing: Text(
                                  note.createdAt.toString().substring(0, 16),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                onTap: () => _openNotePage(note: note),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _openNotePage(),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.transparent),
              child: Text(
                "Menu",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _drawerTile(
              icon: Icons.home,
              title: "Home",
              onTap: () => Navigator.pop(context),
            ),
            _drawerTile(
              icon: Icons.settings,
              title: "Settings",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            _drawerTile(
              icon: Icons.info,
              title: "About",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
