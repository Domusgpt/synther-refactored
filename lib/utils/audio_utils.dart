import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Audio utilities with cross-platform compatibility
class AudioUtils {
  /// Load audio file from assets, with safety checks
  static Future<Uint8List?> loadAudioAsset(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error loading audio asset: $e');
      return null;
    }
  }
  
  /// Convert raw PCM audio (typically from microphone) to Float32List
  /// Handles both 16-bit and 8-bit PCM
  static Float32List convertRawAudioToFloat32(Uint8List rawData, {bool is16Bit = true}) {
    try {
      final int valueCount = is16Bit ? (rawData.length ~/ 2) : rawData.length;
      final Float32List result = Float32List(valueCount);
      
      if (is16Bit) {
        // 16-bit PCM (signed)
        for (int i = 0; i < valueCount; i++) {
          // Combine two bytes to form a 16-bit signed int
          final int value = (rawData[i * 2] & 0xFF) | ((rawData[i * 2 + 1] & 0xFF) << 8);
          // Convert to signed from 2's complement if needed
          final int signedValue = value > 32767 ? value - 65536 : value;
          // Normalize to -1.0 to 1.0
          result[i] = signedValue / 32768.0;
        }
      } else {
        // 8-bit PCM (unsigned, typically)
        for (int i = 0; i < valueCount; i++) {
          // Convert 0-255 to -1.0-1.0
          result[i] = (rawData[i] / 128.0) - 1.0;
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error converting raw audio: $e');
      // Return empty buffer on error
      return Float32List(0);
    }
  }
  
  /// Simple RMS calculation for audio level
  static double calculateRMS(Float32List samples) {
    if (samples.isEmpty) return 0.0;
    
    double sum = 0.0;
    for (int i = 0; i < samples.length; i++) {
      sum += samples[i] * samples[i];
    }
    
    return (sum / samples.length).sqrt();
  }
}
