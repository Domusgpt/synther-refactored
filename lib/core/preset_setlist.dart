import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'audio_preset_library.dart';

/// Represents an entry in a performance setlist. Each entry references a
/// registered preset and can optionally include performer notes.
@immutable
class PresetSetlistEntry {
  const PresetSetlistEntry({
    required this.id,
    required this.presetId,
    this.label,
    this.notes,
    this.cueBeats,
  });

  factory PresetSetlistEntry.fromJson(Map<String, dynamic> json) {
    return PresetSetlistEntry(
      id: json['id'] as String,
      presetId: json['presetId'] as String,
      label: json['label'] as String?,
      notes: json['notes'] as String?,
      cueBeats: (json['cueBeats'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String presetId;
  final String? label;
  final String? notes;
  final double? cueBeats;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'presetId': presetId,
      if (label != null) 'label': label,
      if (notes != null) 'notes': notes,
      if (cueBeats != null) 'cueBeats': cueBeats,
    };
  }

  PresetSetlistEntry copyWith({
    String? id,
    String? presetId,
    String? label,
    String? notes,
    double? cueBeats,
  }) {
    return PresetSetlistEntry(
      id: id ?? this.id,
      presetId: presetId ?? this.presetId,
      label: label ?? this.label,
      notes: notes ?? this.notes,
      cueBeats: cueBeats ?? this.cueBeats,
    );
  }
}

/// Immutable collection of performance slots that reference synth presets.
@immutable
class PresetSetlist {
  const PresetSetlist({
    required this.id,
    required this.name,
    required List<PresetSetlistEntry> entries,
    this.description,
    this.tags = const <String>[],
    this.author,
  }) : _entries = entries;

  factory PresetSetlist.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic value) =>
            PresetSetlistEntry.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);

    return PresetSetlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      author: json['author'] as String?,
      tags:
          (json['tags'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic value) => value.toString())
              .toList(growable: false),
      entries: entries,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? author;
  final List<String> tags;
  final List<PresetSetlistEntry> _entries;

  UnmodifiableListView<PresetSetlistEntry> get entries =>
      UnmodifiableListView<PresetSetlistEntry>(_entries);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (author != null) 'author': author,
      if (tags.isNotEmpty) 'tags': tags,
      'entries': _entries.map((entry) => entry.toJson()).toList(),
    };
  }

  PresetSetlist copyWith({
    String? id,
    String? name,
    String? description,
    String? author,
    List<String>? tags,
    List<PresetSetlistEntry>? entries,
  }) {
    return PresetSetlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      tags: tags ?? this.tags,
      entries: entries ?? _entries,
    );
  }

  PresetSetlistEntry? entryById(String entryId) {
    for (final entry in _entries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  PresetSetlist addEntry(PresetSetlistEntry entry) {
    final updated = List<PresetSetlistEntry>.from(_entries)..add(entry);
    return copyWith(entries: updated);
  }

  PresetSetlist removeEntry(String entryId) {
    final updated = _entries.where((entry) => entry.id != entryId).toList();
    return copyWith(entries: updated);
  }

  PresetSetlist updateEntry(PresetSetlistEntry entry) {
    final updated = _entries
        .map((candidate) => candidate.id == entry.id ? entry : candidate)
        .toList();
    return copyWith(entries: updated);
  }

  PresetSetlist moveEntry(String entryId, int newIndex) {
    if (newIndex < 0 || newIndex >= _entries.length) {
      return this;
    }
    final currentIndex = _entries.indexWhere((entry) => entry.id == entryId);
    if (currentIndex == -1 || currentIndex == newIndex) {
      return this;
    }

    final updated = List<PresetSetlistEntry>.from(_entries);
    final entry = updated.removeAt(currentIndex);
    updated.insert(newIndex, entry);
    return copyWith(entries: updated);
  }
}

/// In-memory registry for setlists. Mirrors the preset library API so callers
/// can manage curated performances alongside presets.
class PresetSetlistLibrary with ChangeNotifier {
  PresetSetlistLibrary._();

  static final PresetSetlistLibrary instance = PresetSetlistLibrary._();

  final SplayTreeMap<String, PresetSetlist> _setlists =
      SplayTreeMap<String, PresetSetlist>();
  bool _builtInsRegistered = false;

  List<PresetSetlist> get allSetlists =>
      List<PresetSetlist>.unmodifiable(_setlists.values);

  PresetSetlist? findById(String id) => _setlists[id];

  void register(PresetSetlist setlist, {bool replaceExisting = true}) {
    if (!replaceExisting && _setlists.containsKey(setlist.id)) {
      return;
    }
    _setlists[setlist.id] = setlist;
    notifyListeners();
  }

  bool remove(String id) {
    final removed = _setlists.remove(id);
    if (removed != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  void upsertEntry(String setlistId, PresetSetlistEntry entry) {
    final existing = _setlists[setlistId];
    if (existing == null) {
      throw ArgumentError.value(setlistId, 'setlistId', 'Unknown setlist id');
    }
    register(existing.updateEntry(entry));
  }

  void removeEntry(String setlistId, String entryId) {
    final existing = _setlists[setlistId];
    if (existing == null) {
      throw ArgumentError.value(setlistId, 'setlistId', 'Unknown setlist id');
    }
    register(existing.removeEntry(entryId));
  }

  void moveEntry(String setlistId, String entryId, int newIndex) {
    final existing = _setlists[setlistId];
    if (existing == null) {
      throw ArgumentError.value(setlistId, 'setlistId', 'Unknown setlist id');
    }
    register(existing.moveEntry(entryId, newIndex));
  }

  void reset() {
    if (_setlists.isEmpty && !_builtInsRegistered) {
      return;
    }
    _setlists.clear();
    _builtInsRegistered = false;
    notifyListeners();
  }

  void ensureBuiltInSetlists() {
    if (_builtInsRegistered) {
      return;
    }
    _builtInsRegistered = true;

    final presetLibrary = AudioPresetLibrary.instance;
    presetLibrary.ensureBuiltInPresets();

    final vaporwaveShowcase = PresetSetlist(
      id: 'factory-vaporwave-showcase',
      name: 'Vaporwave Showcase',
      description:
          'A curated journey through the factory presets designed for live demos.',
      tags: const ['factory', 'demo'],
      entries: const <PresetSetlistEntry>[
        PresetSetlistEntry(
          id: 'slot-opening-pad',
          presetId: 'factory-glow-pad',
          label: 'Opening Glow',
          notes: 'Slow fade-in, focus on modulation wheel for movement.',
          cueBeats: 0,
        ),
        PresetSetlistEntry(
          id: 'slot-laser-pluck',
          presetId: 'factory-laser-pluck',
          label: 'Laser Pluck',
          notes: 'Add arpeggiator sync with transport for rhythmic textures.',
          cueBeats: 32,
        ),
        PresetSetlistEntry(
          id: 'slot-bass-drive',
          presetId: 'factory-submerged-bass',
          label: 'Submerged Bass',
          notes: 'Introduce drive & sustain pedal swells for impact.',
          cueBeats: 64,
        ),
        PresetSetlistEntry(
          id: 'slot-crystal',
          presetId: 'factory-crystal-keys',
          label: 'Crystal Keys',
          notes: 'Close the performance with shimmering chords and slow BPM ramp.',
          cueBeats: 96,
        ),
      ],
    );

    register(vaporwaveShowcase, replaceExisting: false);
  }
}
