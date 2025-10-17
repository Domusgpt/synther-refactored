import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/preset_setlist.dart';

/// Persists [PresetSetlistLibrary] contents to disk so curated performances
/// survive application restarts.
class PresetSetlistPersistence {
  PresetSetlistPersistence({
    required this.library,
    Directory? storageDirectory,
    this.fileName = 'user_setlists.json',
    Duration debounceDuration = const Duration(milliseconds: 400),
    @visibleForTesting File? overrideFile,
  })  : _storageDirectory = storageDirectory ??
            Directory('${Directory.current.path}/build/state'),
        _debounceDuration = debounceDuration,
        _overrideFile = overrideFile {
    _listener = _handleLibraryChanged;
    library.addListener(_listener);
  }

  final PresetSetlistLibrary library;
  final Directory _storageDirectory;
  final String fileName;
  final Duration _debounceDuration;
  final File? _overrideFile;

  late final VoidCallback _listener;
  Timer? _debounceTimer;
  bool _loading = false;

  Future<File> _resolveFile() async {
    if (_overrideFile != null) {
      return _overrideFile!;
    }

    if (!await _storageDirectory.exists()) {
      await _storageDirectory.create(recursive: true);
    }
    return File('${_storageDirectory.path}/$fileName');
  }

  /// Reads previously saved setlists and registers them with the library.
  Future<void> load() async {
    library.ensureBuiltInSetlists();
    if (kIsWeb) {
      debugPrint('PresetSetlistPersistence: Web storage is not available.');
      return;
    }

    final file = await _resolveFile();
    if (!await file.exists()) {
      return;
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final payload = decoded['setlists'];
      if (payload is! List) {
        return;
      }

      _loading = true;
      for (final item in payload) {
        if (item is Map<String, dynamic>) {
          try {
            final setlist = PresetSetlist.fromJson(item);
            library.register(setlist, replaceExisting: true);
          } catch (error) {
            debugPrint('PresetSetlistPersistence: Skipped malformed setlist: $error');
          }
        }
      }
    } catch (error) {
      debugPrint('PresetSetlistPersistence: Failed to load setlists: $error');
    } finally {
      _loading = false;
    }
  }

  void _handleLibraryChanged() {
    if (_loading || kIsWeb) {
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      save();
    });
  }

  /// Serialises the current library state to disk.
  Future<void> save() async {
    if (kIsWeb) {
      return;
    }
    try {
      final file = await _resolveFile();
      final setlists = library.allSetlists
          .map((setlist) => setlist.toJson())
          .toList(growable: false);
      final payload = jsonEncode(<String, dynamic>{'setlists': setlists});
      await file.writeAsString(payload, flush: true);
    } catch (error) {
      debugPrint('PresetSetlistPersistence: Failed to persist setlists: $error');
    }
  }

  /// Stops listening for library changes and cancels pending saves.
  void dispose() {
    library.removeListener(_listener);
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}
