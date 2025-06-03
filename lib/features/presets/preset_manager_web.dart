import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/synth_parameters.dart';
import '../../core/granular_parameters.dart';

/// Web-specific implementation for managing presets using localStorage
class PresetManager {
  static const String _presetStoragePrefix = 'synthesizer_preset_';
  static const String _presetListKey = 'synthesizer_preset_list';
  static const String _lastPresetKey = 'last_preset';
  
  /// Get list of available presets
  static Future<List<String>> getPresetList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_presetListKey) ?? [];
  }
  
  /// Save a preset
  static Future<bool> savePreset({
    required String name,
    required SynthParametersModel synthParams,
    required GranularParameters granularParams,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create preset JSON
      final preset = {
        'name': name,
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'synth': synthParams.toJson(),
        'granular': granularParams.toJson(),
      };
      
      // Save preset data
      final result = await prefs.setString(
        _presetStoragePrefix + name,
        const JsonEncoder.withIndent('  ').convert(preset),
      );
      
      // Update preset list
      final presetList = await getPresetList();
      if (!presetList.contains(name)) {
        presetList.add(name);
        presetList.sort();
        await prefs.setStringList(_presetListKey, presetList);
      }
      
      // Save as last preset
      await prefs.setString(_lastPresetKey, name);
      
      return result;
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
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_presetStoragePrefix + name);
      
      if (jsonString == null) {
        return false;
      }
      
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
      final prefs = await SharedPreferences.getInstance();
      
      // Remove preset data
      final result = await prefs.remove(_presetStoragePrefix + name);
      
      // Update preset list
      final presetList = await getPresetList();
      if (presetList.contains(name)) {
        presetList.remove(name);
        await prefs.setStringList(_presetListKey, presetList);
      }
      
      return result;
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
}