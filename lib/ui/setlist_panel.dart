import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio_engine.dart';
import '../core/audio_preset_library.dart';
import '../core/preset_setlist.dart';

class SetlistManagerPanel extends StatefulWidget {
  const SetlistManagerPanel({super.key});

  @override
  State<SetlistManagerPanel> createState() => _SetlistManagerPanelState();
}

class _SetlistManagerPanelState extends State<SetlistManagerPanel> {
  final PresetSetlistLibrary _library = PresetSetlistLibrary.instance;
  late final VoidCallback _libraryListener;
  String? _selectedSetlistId;

  @override
  void initState() {
    super.initState();
    _library.ensureBuiltInSetlists();
    final setlists = _library.allSetlists;
    if (setlists.isNotEmpty) {
      _selectedSetlistId = setlists.first.id;
    }
    _libraryListener = () {
      final all = _library.allSetlists;
      setState(() {
        if (all.isEmpty) {
          _selectedSetlistId = null;
        } else if (_selectedSetlistId == null ||
            !all.any((setlist) => setlist.id == _selectedSetlistId)) {
          _selectedSetlistId = all.first.id;
        }
      });
    };
    _library.addListener(_libraryListener);
  }

  @override
  void dispose() {
    _library.removeListener(_libraryListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final setlists = _library.allSetlists;
    final selected = setlists.firstWhere(
      (setlist) => setlist.id == _selectedSetlistId,
      orElse: () => setlists.isEmpty ? null : setlists.first,
    );

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF090B1F).withOpacity(0.95),
                const Color(0xFF040511).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAAFFD700),
                blurRadius: 28,
                spreadRadius: -14,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Consumer<AudioEngine>(
            builder: (context, engine, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Performance Setlists',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colorScheme.tertiary,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              setlists.isEmpty
                                  ? 'Curate your first performance by registering a setlist and adding presets from the library.'
                                  : 'Manage live showcases, reorder cues, and trigger slots directly from the holographic HUD.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close setlist manager',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 220,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: setlists.isEmpty
                                    ? _buildEmptyListState()
                                    : ListView.separated(
                                        itemCount: setlists.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final setlist = setlists[index];
                                          final isSelected = setlist.id == selected?.id;
                                          final isFactory = setlist.tags.contains('factory');
                                          return _buildSetlistListTile(
                                            setlist: setlist,
                                            selected: isSelected,
                                            isFactory: isFactory,
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.tonalIcon(
                                onPressed: _createSetlist,
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('New setlist'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: selected == null
                              ? _buildEmptySelectionState()
                              : _buildSetlistDetail(context, engine, selected),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyListState() {
    return const Center(
      child: Text(
        'No setlists registered yet',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildEmptySelectionState() {
    return const Center(
      child: Text(
        'Select a setlist to edit slots and cues',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildSetlistListTile({
    required PresetSetlist setlist,
    required bool selected,
    required bool isFactory,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      tileColor: selected ? const Color(0x33212121) : const Color(0x11000000),
      title: Text(
        setlist.name,
        style: TextStyle(
          color: Colors.white,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: setlist.description == null
          ? null
          : Text(
              setlist.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
      trailing: isFactory
          ? const Icon(Icons.auto_awesome, color: Colors.white38)
          : IconButton(
              tooltip: 'Delete setlist',
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              onPressed: () {
                _library.remove(setlist.id);
              },
            ),
      onTap: () => setState(() => _selectedSetlistId = setlist.id),
      onLongPress: isFactory ? null : () => _renameSetlist(setlist),
    );
  }

  Widget _buildSetlistDetail(
    BuildContext context,
    AudioEngine engine,
    PresetSetlist setlist,
  ) {
    final entries = setlist.entries;
    final isFactory = setlist.tags.contains('factory');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                setlist.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (!isFactory)
              IconButton(
                tooltip: 'Duplicate setlist',
                onPressed: () => _duplicateSetlist(setlist),
                icon: const Icon(Icons.content_copy, color: Colors.white70),
              ),
          ],
        ),
        if (setlist.description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              setlist.description!,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        Expanded(
          child: entries.isEmpty
              ? _buildEmptyEntriesState()
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isActive = engine.activeSetlistEntry?.id == entry.id;
                    return _buildEntryCard(
                      context: context,
                      engine: engine,
                      setlist: setlist,
                      entry: entry,
                      index: index,
                      total: entries.length,
                      isActive: isActive,
                      isFactory: isFactory,
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (!isFactory)
              FilledButton.tonalIcon(
                onPressed: () => _addEntry(setlist),
                icon: const Icon(Icons.queue_music),
                label: const Text('Add preset to setlist'),
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                engine.clearSetlistContext(notify: true);
              },
              icon: const Icon(Icons.highlight_off),
              label: const Text('Clear active cue'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyEntriesState() {
    return const Center(
      child: Text(
        'No entries yet – add presets to build your performance.',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildEntryCard({
    required BuildContext context,
    required AudioEngine engine,
    required PresetSetlist setlist,
    required PresetSetlistEntry entry,
    required int index,
    required int total,
    required bool isActive,
    required bool isFactory,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? const Color(0xFF00FFFF) : Colors.white10),
        gradient: LinearGradient(
          colors: [
            const Color(0x221A1A2E),
            const Color(0x3310101A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.label ?? entry.presetId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Load in engine',
                onPressed: () async {
                  await engine.loadSetlistEntry(
                    setlistId: setlist.id,
                    entryId: entry.id,
                  );
                },
                icon: const Icon(Icons.play_circle_outline, color: Colors.white70),
              ),
              if (!isFactory)
                IconButton(
                  tooltip: 'Edit entry',
                  onPressed: () => _editEntry(setlist, entry),
                  icon: const Icon(Icons.edit_note, color: Colors.white70),
                ),
              if (!isFactory)
                IconButton(
                  tooltip: 'Remove entry',
                  onPressed: () => _library.removeEntry(setlist.id, entry.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.white54),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Preset ID: ${entry.presetId}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          if (entry.notes != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                entry.notes!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          if (entry.cueBeats != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Cue at beat ${entry.cueBeats!.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          if (!isFactory)
            Row(
              children: [
                IconButton(
                  tooltip: 'Move up',
                  onPressed: index == 0
                      ? null
                      : () => _library.moveEntry(setlist.id, entry.id, index - 1),
                  icon: const Icon(Icons.arrow_upward, color: Colors.white70),
                ),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: index == total - 1
                      ? null
                      : () => _library.moveEntry(setlist.id, entry.id, index + 1),
                  icon: const Icon(Icons.arrow_downward, color: Colors.white70),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _createSetlist() async {
    final result = await showDialog<_SetlistEditorResult>(
      context: context,
      builder: (context) => const _SetlistEditorDialog(),
    );
    if (result == null) {
      return;
    }
    final id = _generateSetlistId(result.name);
    final setlist = PresetSetlist(
      id: id,
      name: result.name,
      description: result.description,
      author: result.author,
      tags: result.tags,
      entries: const <PresetSetlistEntry>[],
    );
    _library.register(setlist);
    setState(() => _selectedSetlistId = id);
  }

  Future<void> _renameSetlist(PresetSetlist setlist) async {
    final result = await showDialog<_SetlistEditorResult>(
      context: context,
      builder: (context) => _SetlistEditorDialog(initial: setlist),
    );
    if (result == null) {
      return;
    }
    final updated = setlist.copyWith(
      name: result.name,
      description: result.description,
      author: result.author,
      tags: result.tags,
    );
    _library.register(updated);
  }

  Future<void> _duplicateSetlist(PresetSetlist setlist) async {
    final newId = _generateSetlistId('${setlist.id}-copy');
    final duplicate = setlist.copyWith(
      id: newId,
      name: '${setlist.name} Copy',
    );
    _library.register(duplicate);
    setState(() => _selectedSetlistId = newId);
  }

  Future<void> _addEntry(PresetSetlist setlist) async {
    final result = await showModalBottomSheet<PresetSetlistEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SetlistEntrySheet(setlistId: setlist.id),
    );
    if (result == null) {
      return;
    }
    _library.register(setlist.addEntry(result));
  }

  Future<void> _editEntry(PresetSetlist setlist, PresetSetlistEntry entry) async {
    final result = await showModalBottomSheet<PresetSetlistEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SetlistEntrySheet(
        setlistId: setlist.id,
        existing: entry,
      ),
    );
    if (result == null) {
      return;
    }
    _library.upsertEntry(setlist.id, result);
  }

  String _generateSetlistId(String name) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'(^-|-$)'), '');
    var candidate = base.isEmpty ? 'setlist' : base;
    var suffix = 1;
    while (_library.findById(candidate) != null) {
      candidate = '$base-$suffix';
      suffix++;
    }
    return candidate;
  }
}

class _SetlistEditorResult {
  _SetlistEditorResult({
    required this.name,
    this.description,
    this.author,
    this.tags = const <String>[],
  });

  final String name;
  final String? description;
  final String? author;
  final List<String> tags;
}

class _SetlistEditorDialog extends StatefulWidget {
  const _SetlistEditorDialog({this.initial});

  final PresetSetlist? initial;

  @override
  State<_SetlistEditorDialog> createState() => _SetlistEditorDialogState();
}

class _SetlistEditorDialogState extends State<_SetlistEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _authorController;
  late final TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _descriptionController = TextEditingController(text: initial?.description ?? '');
    _authorController = TextEditingController(text: initial?.author ?? '');
    _tagsController = TextEditingController(
      text: initial == null ? '' : initial.tags.join(', '),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF040511),
      title: Text(
        widget.initial == null ? 'Create setlist' : 'Edit setlist',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author / Performer',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              return;
            }
            final tags = _tagsController.text
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList();
            Navigator.of(context).pop(
              _SetlistEditorResult(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                author: _authorController.text.trim().isEmpty
                    ? null
                    : _authorController.text.trim(),
                tags: tags,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SetlistEntrySheet extends StatefulWidget {
  const _SetlistEntrySheet({
    required this.setlistId,
    this.existing,
  });

  final String setlistId;
  final PresetSetlistEntry? existing;

  @override
  State<_SetlistEntrySheet> createState() => _SetlistEntrySheetState();
}

class _SetlistEntrySheetState extends State<_SetlistEntrySheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _notesController;
  late final TextEditingController _cueController;
  String? _selectedPresetId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _selectedPresetId = existing?.presetId;
    _labelController = TextEditingController(text: existing?.label ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _cueController = TextEditingController(
      text: existing?.cueBeats == null ? '' : existing!.cueBeats!.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _notesController.dispose();
    _cueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presetLibrary = AudioPresetLibrary.instance;
    presetLibrary.ensureBuiltInPresets();
    final presets = presetLibrary.allPresets();

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        gradient: LinearGradient(
          colors: [Color(0xFF040511), Color(0xFF080B1F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.existing == null ? 'Add setlist entry' : 'Edit setlist entry',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPresetId,
              items: presets
                  .map(
                    (preset) => DropdownMenuItem<String>(
                      value: preset.metadata.id,
                      child: Text(preset.metadata.name ?? preset.metadata.id),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedPresetId = value),
              decoration: const InputDecoration(
                labelText: 'Preset',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Slot label',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Performer notes',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              maxLines: 3,
            ),
            TextField(
              controller: _cueController,
              decoration: const InputDecoration(
                labelText: 'Cue beat (optional)',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _selectedPresetId == null
                    ? null
                    : () {
                        final cueText = _cueController.text.trim();
                        final cue = cueText.isEmpty ? null : double.tryParse(cueText);
                        final entry = PresetSetlistEntry(
                          id: widget.existing?.id ?? _generateEntryId(),
                          presetId: _selectedPresetId!,
                          label: _labelController.text.trim().isEmpty
                              ? null
                              : _labelController.text.trim(),
                          notes: _notesController.text.trim().isEmpty
                              ? null
                              : _notesController.text.trim(),
                          cueBeats: cue,
                        );
                        Navigator.of(context).pop(entry);
                      },
                icon: const Icon(Icons.save_alt),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateEntryId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${widget.setlistId}-entry-$timestamp';
  }
}
