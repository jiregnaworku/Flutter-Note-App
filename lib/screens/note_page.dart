import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home_page.dart';

class NotePage extends StatefulWidget {
  final Note? note;

  const NotePage({super.key, this.note});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isSaving = false;
  late final Box<Note> _notesBox;
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );

    _notesBox = Hive.box<Note>('notesBox');

    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _onSavePressed() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save an empty note')),
      );
      return;
    }

    await _scaleController.reverse();
    await _scaleController.forward();
    setState(() => _isSaving = true);

    try {
      if (widget.note != null) {
        widget.note!
          ..title = title.isEmpty ? 'Untitled' : title
          ..content = content
          ..save();
      } else {
        final note = Note(
          title: title.isEmpty ? 'Untitled' : title,
          content: content,
        );
        await _notesBox.add(note);
      }

      if (!mounted) return;
      await _showSuccessAnimation();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save note')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showSuccessAnimation() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Note saved')));
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool expands = false,
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
        maxLines: expands ? null : maxLines,
        expands: expands,
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
    final isEditing = widget.note != null;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Note' : 'Create Note')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(
                controller: _titleController,
                hint: 'Title',
                maxLines: 1,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _buildInputField(
                  controller: _contentController,
                  hint: 'Write your note...',
                  expands: true,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                child: AnimatedBuilder(
                  animation: _scaleController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleController.value,
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTapDown: (_) => _scaleController.reverse(),
                    onTapUp: (_) => _scaleController.forward(),
                    onTapCancel: () => _scaleController.forward(),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _onSavePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? CircularProgressIndicator(
                              color: scheme.onPrimary,
                              strokeWidth: 2.5,
                            )
                          : Text(
                              isEditing ? 'Save Changes' : 'Save Note',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
