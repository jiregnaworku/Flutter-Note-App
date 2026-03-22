import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'note_page.dart';
import 'about_page.dart';
import 'settings_page.dart';
import 'view_note_page.dart';
import 'package:intl/intl.dart';

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
  String _searchQuery = '';

  late final Box settingsBox;
  late Set<dynamic> _pinnedKeys;
  final Set<dynamic> _selectedKeys = <dynamic>{};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _notesBox = Hive.box<Note>('notesBox');
    settingsBox = Hive.box('settingsBox');
    _pinnedKeys = Set<dynamic>.from(
      (settingsBox.get('pinnedKeys', defaultValue: <dynamic>[]) as List),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Note> get _filteredNotes {
    final allNotes = _notesBox.values.toList();
    final filtered = _searchQuery.isEmpty
        ? allNotes
        : allNotes
              .where(
                (note) =>
                    note.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    note.content.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

    // Sort: pinned first, then by createdAt desc
    filtered.sort((a, b) {
      final ap = _isPinned(a) ? 1 : 0;
      final bp = _isPinned(b) ? 1 : 0;
      if (ap != bp) return bp.compareTo(ap); // pinned (1) before not pinned (0)
      return b.createdAt.compareTo(a.createdAt);
    });
    return filtered;
  }

  bool _isPinned(Note note) => _pinnedKeys.contains(note.key);

  void _togglePin(Note note) {
    final key = note.key;
    setState(() {
      if (_pinnedKeys.contains(key)) {
        _pinnedKeys.remove(key);
      } else {
        _pinnedKeys.add(key);
      }
      settingsBox.put('pinnedKeys', _pinnedKeys.toList());
    });
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return DateFormat('MMM d, HH:mm').format(dt);
  }

  Future<void> _deleteNoteWithUndo(Note note) async {
    final title = note.title;
    final content = note.content;
    final createdAt = note.createdAt;
    final wasPinned = _isPinned(note);

    await note.delete();
    setState(() {
      _pinnedKeys.remove(note.key);
      settingsBox.put('pinnedKeys', _pinnedKeys.toList());
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final restored = Note(
              title: title,
              content: content,
              createdAt: createdAt,
            );
            final newKey = await _notesBox.add(restored);
            if (wasPinned) {
              setState(() {
                _pinnedKeys.add(newKey);
                settingsBox.put('pinnedKeys', _pinnedKeys.toList());
              });
            } else {
              setState(() {});
            }
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openNotePage({Note? note}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotePage(note: note)),
    );
    setState(() {});
  }

  Future<void> _openViewNotePage(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewNotePage(note: note)),
    );
    setState(() {});
  }

  void _toggleSelection(Note note) {
    final key = note.key;
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
      _selectionMode = _selectedKeys.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedKeys.clear();
      _selectionMode = false;
    });
  }

  Future<void> _pinSelected(bool pin) async {
    setState(() {
      for (final key in _selectedKeys) {
        if (pin) {
          _pinnedKeys.add(key);
        } else {
          _pinnedKeys.remove(key);
        }
      }
      settingsBox.put('pinnedKeys', _pinnedKeys.toList());
      _selectedKeys.clear();
      _selectionMode = false;
    });
  }

  Future<void> _deleteSelected() async {
    // Capture notes to restore on undo
    final notesMap = <dynamic, Note>{};
    for (final n in _notesBox.values) {
      if (_selectedKeys.contains(n.key)) notesMap[n.key] = n;
    }
    // Remove and unpin
    for (final key in _selectedKeys) {
      final note = notesMap[key];
      if (note != null) await note.delete();
      _pinnedKeys.remove(key);
    }
    settingsBox.put('pinnedKeys', _pinnedKeys.toList());
    setState(() {
      _selectedKeys.clear();
      _selectionMode = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${notesMap.length} notes'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            for (final entry in notesMap.entries) {
              final restored = Note(
                title: entry.value.title,
                content: entry.value.content,
                createdAt: entry.value.createdAt,
              );
              final newKey = await _notesBox.add(restored);
              if (_pinnedKeys.contains(entry.key)) {
                // keep previous pin state if it was pinned
                _pinnedKeys.add(newKey);
              }
            }
            settingsBox.put('pinnedKeys', _pinnedKeys.toList());
            setState(() {});
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final notes = _filteredNotes;
    final totalNotes = _notesBox.length;
    final pinnedNotes = _pinnedKeys.length;

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('${_selectedKeys.length} selected')
            : const Text('My Notes'),
        actions: _selectionMode
            ? [
                IconButton(
                  tooltip: 'Pin',
                  onPressed: () => _pinSelected(true),
                  icon: const Icon(Icons.push_pin_outlined),
                ),
                IconButton(
                  tooltip: 'Unpin',
                  onPressed: () => _pinSelected(false),
                  icon: const Icon(Icons.push_pin),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: _deleteSelected,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
                IconButton(
                  tooltip: 'Cancel',
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.close),
                ),
              ]
            : null,
      ),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          context: context,
                          label: 'Total notes',
                          value: '$totalNotes',
                          icon: Icons.sticky_note_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          context: context,
                          label: 'Pinned',
                          value: '$pinnedNotes',
                          icon: Icons.push_pin_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: notes.isEmpty
                  ? _buildEmptyState(context)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        int crossAxisCount = 2;
                        if (width > 1200) {
                          crossAxisCount = 5;
                        } else if (width > 900) {
                          crossAxisCount = 4;
                        } else if (width > 600) {
                          crossAxisCount = 3;
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.08,
                              ),
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            final selected = _selectedKeys.contains(note.key);
                            return _buildNoteCard(
                              note: note,
                              selected: selected,
                              scheme: scheme,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          if (_selectionMode) {
            _clearSelection();
            return;
          }
          _openNotePage();
        },
      ),
    );
  }

  Widget _buildNoteCard({
    required Note note,
    required bool selected,
    required ColorScheme scheme,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: () => _toggleSelection(note),
          onTap: () {
            if (_selectionMode) {
              _toggleSelection(note);
            } else {
              _openViewNotePage(note);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (_isPinned(note))
                      Icon(Icons.push_pin, size: 18, color: scheme.primary),
                    if (!_selectionMode)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        onSelected: (value) async {
                          switch (value) {
                            case 'view':
                              await _openViewNotePage(note);
                              break;
                            case 'edit':
                              await _openNotePage(note: note);
                              break;
                            case 'pin':
                              _togglePin(note);
                              break;
                            case 'delete':
                              await _deleteNoteWithUndo(note);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: ListTile(
                              leading: Icon(Icons.visibility),
                              title: Text('View'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'pin',
                            child: ListTile(
                              leading: Icon(
                                _isPinned(note)
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                              ),
                              title: Text(_isPinned(note) ? 'Unpin' : 'Pin'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete),
                              title: Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    note.content,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(note.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (_selectionMode)
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
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

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.note_alt_outlined,
                color: scheme.onPrimaryContainer,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture ideas, tasks, and thoughts in one place.',
              style: TextStyle(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _openNotePage,
              icon: const Icon(Icons.add),
              label: const Text('Create note'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Menu',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _drawerTile(
            icon: Icons.home,
            title: 'Home',
            onTap: () => Navigator.pop(context),
          ),
          _drawerTile(
            icon: Icons.settings,
            title: 'Settings',
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
            title: 'About',
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
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
