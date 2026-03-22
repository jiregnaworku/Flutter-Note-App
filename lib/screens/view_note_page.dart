import 'package:flutter/material.dart';
import 'home_page.dart';
import 'note_page.dart';

class ViewNotePage extends StatefulWidget {
  final Note note;
  const ViewNotePage({super.key, required this.note});

  @override
  State<ViewNotePage> createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNotePage> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        maxLines: expand ? null : maxLines,
        expands: expand,
        readOnly: readOnly,
        cursorColor: scheme.primary,
        style: TextStyle(color: scheme.onSurface, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: scheme.onSurfaceVariant),
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Note'),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteNote),
          IconButton(
            icon: Icon(Icons.edit, color: scheme.primary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotePage(note: widget.note)),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildInputField(
                controller: titleController,
                hint: 'Title',
                maxLines: 1,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildInputField(
                  controller: contentController,
                  hint: 'No content',
                  expand: true,
                  readOnly: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
