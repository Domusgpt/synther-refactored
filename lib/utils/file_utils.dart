import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:shared_preferences/shared_preferences.dart';

/// File utilities with web compatibility
class FileUtils {
  /// Get the application documents directory, with web fallback
  static Future<Directory?> getAppDocumentsDirectory() async {
    try {
      if (kIsWeb) {
        // Web doesn't have filesystem access the same way
        // Return null and use SharedPreferences instead
        return null;
      } else {
        return await path_provider.getApplicationDocumentsDirectory();
      }
    } catch (e) {
      debugPrint('Error getting app documents directory: $e');
      return null;
    }
  }
  
  /// Save string data to a file with web fallback using SharedPreferences
  static Future<bool> saveToFile(String filename, String data) async {
    try {
      if (kIsWeb) {
        // On web, use SharedPreferences instead
        final prefs = await SharedPreferences.getInstance();
        return await prefs.setString('file_$filename', data);
      } else {
        final directory = await getAppDocumentsDirectory();
        if (directory == null) return false;
        
        final file = File('${directory.path}/$filename');
        await file.writeAsString(data);
        return true;
      }
    } catch (e) {
      debugPrint('Error saving to file: $e');
      return false;
    }
  }
  
  /// Read string data from a file with web fallback using SharedPreferences
  static Future<String?> readFromFile(String filename) async {
    try {
      if (kIsWeb) {
        // On web, use SharedPreferences instead
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('file_$filename');
      } else {
        final directory = await getAppDocumentsDirectory();
        if (directory == null) return null;
        
        final file = File('${directory.path}/$filename');
        if (await file.exists()) {
          return await file.readAsString();
        } else {
          return null;
        }
      }
    } catch (e) {
      debugPrint('Error reading from file: $e');
      return null;
    }
  }
  
  /// Delete a file with web fallback using SharedPreferences
  static Future<bool> deleteFile(String filename) async {
    try {
      if (kIsWeb) {
        // On web, use SharedPreferences instead
        final prefs = await SharedPreferences.getInstance();
        return await prefs.remove('file_$filename');
      } else {
        final directory = await getAppDocumentsDirectory();
        if (directory == null) return false;
        
        final file = File('${directory.path}/$filename');
        if (await file.exists()) {
          await file.delete();
          return true;
        } else {
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
  
  /// List files in a directory with web fallback using SharedPreferences
  static Future<List<String>> listFiles(String? prefix) async {
    try {
      if (kIsWeb) {
        // On web, use SharedPreferences keys with 'file_' prefix
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        final fileKeys = keys.where((key) => key.startsWith('file_'));
        
        // If prefix is provided, filter further
        if (prefix != null && prefix.isNotEmpty) {
          return fileKeys
              .where((key) => key.startsWith('file_$prefix'))
              .map((key) => key.substring(5)) // Remove 'file_' prefix
              .toList();
        } else {
          return fileKeys
              .map((key) => key.substring(5)) // Remove 'file_' prefix
              .toList();
        }
      } else {
        final directory = await getAppDocumentsDirectory();
        if (directory == null) return [];
        
        final List<FileSystemEntity> entities = await directory.list().toList();
        final files = entities
            .whereType<File>()
            .map((file) => file.path.split(Platform.pathSeparator).last)
            .toList();
        
        // If prefix is provided, filter by prefix
        if (prefix != null && prefix.isNotEmpty) {
          return files.where((file) => file.startsWith(prefix)).toList();
        } else {
          return files;
        }
      }
    } catch (e) {
      debugPrint('Error listing files: $e');
      return [];
    }
  }
  
  /// Save structured data to a file with web fallback
  static Future<bool> saveJsonToFile(String filename, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    return saveToFile(filename, jsonString);
  }
  
  /// Read structured data from a file with web fallback
  static Future<Map<String, dynamic>?> readJsonFromFile(String filename) async {
    final jsonString = await readFromFile(filename);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error parsing JSON from file: $e');
        return null;
      }
    }
    return null;
  }
}
