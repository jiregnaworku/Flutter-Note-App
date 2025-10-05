import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
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
  late final Box settingsBox;
  late Color accentColor;
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

      await _showSuccessAnimation();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save note')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _showSuccessAnimation() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Widget animationWidget;
        try {
          animationWidget = Lottie.asset(
            'assets/lottie/success.json',
            width: 180,
            height: 180,
            repeat: false,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.color(const ['**'], value: accentColor),
              ],
            ),
            onLoaded: (composition) {
              Future.delayed(composition.duration, () {
                if (Navigator.canPop(context)) Navigator.of(context).pop();
              });
            },
          );
        } catch (_) {
          animationWidget = Icon(
            Icons.check_circle,
            color: accentColor,
            size: 120,
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (Navigator.canPop(context)) Navigator.of(context).pop();
          });
        }
        return Center(
          child: Material(color: Colors.transparent, child: animationWidget),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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
    final isEditing = widget.note != null;

    return Scaffold(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  isEditing ? "Edit Note" : "Create a Note",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildInputField(
                  controller: _titleController,
                  hint: "Title",
                  maxLines: 1,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _contentController,
                  hint: "Content",
                  maxLines: 6,
                ),
                const SizedBox(height: 32),
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
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentColor, accentColor.withOpacity(0.8)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _onSavePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                )
                              : Text(
                                  isEditing ? "Save Changes" : "Save Note",
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
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
      ),
    );
  }
}
