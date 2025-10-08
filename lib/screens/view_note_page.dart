import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home_page.dart';
import 'note_page.dart';

class ViewNotePage extends StatefulWidget {
  final Note note;
  const ViewNotePage({super.key, required this.note});

  @override
  State<ViewNotePage> createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNotePage> {
  late Box settingsBox;
  late Color accentColor;

  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settingsBox');

    accentColor = Color(
      settingsBox.get('accentColor', defaultValue: Colors.orangeAccent.value),
    );

    // Listen for dynamic accent color changes
    settingsBox.watch(key: 'accentColor').listen((event) {
      setState(() {
        accentColor = Color(event.value);
      });
    });

    titleController = TextEditingController(text: widget.note.title);
    contentController = TextEditingController(text: widget.note.content);
  }

  void _deleteNote() {
    widget.note.delete();
    Navigator.pop(context);
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool expand = false,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        maxLines: expand ? null : maxLines,
        expands: expand,
        readOnly: readOnly,
        cursorColor: Colors.white,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("View Note"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteNote,
          ),
          IconButton(
            icon: Icon(Icons.edit, color: accentColor),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotePage(note: widget.note),
                ),
              );
              // Refresh controllers after editing
              setState(() {
                titleController.text = widget.note.title;
                contentController.text = widget.note.content;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F2B96), Color(0xFF0CBABA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInputField(
                  controller: titleController,
                  hint: "Title",
                  maxLines: 1,
                  readOnly: true,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildInputField(
                    controller: contentController,
                    hint: "Start typing your note...",
                    expand: true,
                    readOnly: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
