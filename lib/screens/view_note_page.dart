import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ViewNotePage extends StatefulWidget {
  final dynamic noteKey;
  const ViewNotePage({super.key, required this.noteKey});

  @override
  State<ViewNotePage> createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNotePage> {
  late Box notesBox;
  late Box settingsBox;
  late Color accentColor;

  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    notesBox = Hive.box('notesBox');
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

    final note = Map<String, dynamic>.from(notesBox.get(widget.noteKey));
    titleController = TextEditingController(text: note['title']);
    contentController = TextEditingController(text: note['content']);
  }

  void _saveNote() {
    notesBox.put(widget.noteKey, {
      "title": titleController.text.isEmpty ? "Untitled" : titleController.text,
      "content": contentController.text,
      "createdAt": DateTime.now().toIso8601String(),
      "isFavorite": false,
    });
    Navigator.pop(context);
  }

  void _deleteNote() {
    notesBox.delete(widget.noteKey);
    Navigator.pop(context);
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool expand = false,
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
        title: const Text("View & Edit Note"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteNote,
          ),
          IconButton(
            icon: Icon(Icons.save, color: accentColor),
            onPressed: _saveNote,
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
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildInputField(
                    controller: contentController,
                    hint: "Start typing your note...",
                    expand: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.save),
                        label: const Text(
                          "Save",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text(
                          "Delete",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
