import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/voice_allocator.dart';

void main() {
  group('VoiceAllocator', () {
    test('allocates sequential voice ids and tracks active notes', () {
      final clock = _FakeClock();
      final allocator = VoiceAllocator(maxVoices: 4, clock: clock.tick);

      final first = allocator.allocate(60, 0.8);
      final second = allocator.allocate(64, 0.6);
      final third = allocator.allocate(67, 0.5);

      expect(first.voice.voiceId, isNot(equals(0)));
      expect(second.voice.voiceId, isNot(equals(0)));
      expect(third.voice.voiceId, isNot(equals(0)));
      expect(
        {first.voice.voiceId, second.voice.voiceId, third.voice.voiceId}.length,
        3,
      );

      expect(allocator.activeVoiceCount, 3);
      expect(allocator.activeNotes, containsAll(<int>[60, 64, 67]));

      final released = allocator.release(64);
      expect(released, isNotNull);
      expect(released!.note, 64);
      expect(allocator.activeVoiceCount, 2);
      expect(allocator.activeNotes, isNot(contains(64)));
    });

    test('steals quietest voice first and oldest on velocity tie', () {
      final clock = _FakeClock();
      final allocator = VoiceAllocator(maxVoices: 2, clock: clock.tick);

      allocator.allocate(60, 0.6);
      clock.advance(const Duration(milliseconds: 5));
      allocator.allocate(64, 0.6);

      final allocation = allocator.allocate(67, 0.6);

      expect(allocation.stolenVoices, hasLength(1));
      expect(allocation.stolenVoices.single.note, 60);
      expect(allocator.activeNotes, containsAll(<int>[64, 67]));
    });

    test('updateMaxVoices releases quiet voices until limit satisfied', () {
      final clock = _FakeClock();
      final allocator = VoiceAllocator(maxVoices: 4, clock: clock.tick);

      allocator.allocate(60, 0.9);
      allocator.allocate(64, 0.3);
      allocator.allocate(67, 0.7);
      allocator.allocate(69, 0.5);

      final released = allocator.updateMaxVoices(2);

      expect(released, hasLength(2));
      expect(released.map((voice) => voice.note), containsAll(<int>[64, 69]));
      expect(allocator.activeVoiceCount, 2);
      expect(allocator.maxVoices, 2);
    });
  });
}

class _FakeClock {
  DateTime _now = DateTime.fromMillisecondsSinceEpoch(0);

  DateTime tick() {
    _now = _now.add(const Duration(milliseconds: 1));
    return _now;
  }

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}
