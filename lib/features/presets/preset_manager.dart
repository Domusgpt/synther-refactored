import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/synth_parameters.dart';
import '../../core/granular_parameters.dart';

/// Manages loading and saving of synthesizer presets
class PresetManager {
  static const String _presetDirName = 'synthesizer_presets';
  static const String _lastPresetKey = 'last_preset';
  
  // Get the directory where presets are stored
  static Future<Directory> _getPresetDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final presetDir = Directory('${appDocDir.path}/$_presetDirName');
    
    if (!await presetDir.exists()) {
      await presetDir.create(recursive: true);
    }
    
    return presetDir;
  }
  
  /// Get list of available presets
  static Future<List<String>> getPresetList() async {
    final presetDir = await _getPresetDirectory();
    final files = await presetDir.list().toList();
    
    return files
        .where((file) => file.path.endsWith('.json'))
        .map((file) => basenameWithoutExtension(file.path))
        .toList()
      ..sort();
  }
  
  /// Save a preset
  static Future<bool> savePreset({
    required String name,
    required SynthParametersModel synthParams,
    required GranularParameters granularParams,
  }) async {
    try {
      final presetDir = await _getPresetDirectory();
      final file = File('${presetDir.path}/$name.json');
      
      final preset = {
        'name': name,
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'synth': synthParams.toJson(),
        'granular': granularParams.toJson(),
      };
      
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(preset),
      );
      
      // Save as last preset
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastPresetKey, name);
      
      return true;
    } catch (e) {
      debugPrint('Error saving preset: $e');
      return false;
    }
  }
  
  /// Load a preset
  static Future<bool> loadPreset({
    required String name,
    required SynthParametersModel synthParams,
    required GranularParameters granularParams,
  }) async {
    try {
      final presetDir = await _getPresetDirectory();
      final file = File('${presetDir.path}/$name.json');
      
      if (!await file.exists()) {
        return false;
      }
      
      final jsonString = await file.readAsString();
      final preset = jsonDecode(jsonString);
      
      // Load synth parameters
      if (preset['synth'] != null) {
        synthParams.loadFromJson(preset['synth']);
      }
      
      // Load granular parameters
      if (preset['granular'] != null) {
        granularParams.loadFromJson(preset['granular']);
      }
      
      // Save as last preset
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastPresetKey, name);
      
      return true;
    } catch (e) {
      debugPrint('Error loading preset: $e');
      return false;
    }
  }
  
  /// Delete a preset
  static Future<bool> deletePreset(String name) async {
    try {
      final presetDir = await _getPresetDirectory();
      final file = File('${presetDir.path}/$name.json');
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error deleting preset: $e');
      return false;
    }
  }
  
  /// Get the last loaded preset name
  static Future<String?> getLastPresetName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastPresetKey);
  }
  
  /// Export preset as string (for sharing)
  static Future<String?> exportPreset({
    required String name,
    required SynthParametersModel synthParams,
    required GranularParameters granularParams,
  }) async {
    try {
      final preset = {
        'name': name,
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'synth': synthParams.toJson(),
        'granular': granularParams.toJson(),
      };
      
      return const JsonEncoder.withIndent('  ').convert(preset);
    } catch (e) {
      debugPrint('Error exporting preset: $e');
      return null;
    }
  }
  
  /// Import preset from string
  static Future<bool> importPreset({
    required String jsonString,
    required SynthParametersModel synthParams,
    required GranularParameters granularParams,
  }) async {
    try {
      final preset = jsonDecode(jsonString);
      
      // Load synth parameters
      if (preset['synth'] != null) {
        synthParams.loadFromJson(preset['synth']);
      }
      
      // Load granular parameters
      if (preset['granular'] != null) {
        granularParams.loadFromJson(preset['granular']);
      }
      
      // Save the preset if it has a name
      if (preset['name'] != null) {
        await savePreset(
          name: preset['name'],
          synthParams: synthParams,
          granularParams: granularParams,
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error importing preset: $e');
      return false;
    }
  }
  
  // Get the base filename without extension
  static String basenameWithoutExtension(String path) {
    final file = File(path);
    final name = file.path.split(Platform.pathSeparator).last;
    final index = name.lastIndexOf('.');
    return index != -1 ? name.substring(0, index) : name;
  }
}