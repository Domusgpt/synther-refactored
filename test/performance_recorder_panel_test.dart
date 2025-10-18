import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:synther_holographic_pro/core/audio_engine.dart';
import 'package:synther_holographic_pro/core/basic_audio_backend.dart';
import 'package:synther_holographic_pro/ui/performance_recorder_panel.dart';

void main() {
  testWidgets('PerformanceRecorderPanel drives recorder lifecycle', (tester) async {
    final engine = AudioEngine(backend: BasicAudioBackend());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: engine,
        child: const MaterialApp(
          home: Scaffold(body: PerformanceRecorderPanel()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final recorder = engine.performanceRecorder;
    expect(recorder, isNotNull);
    expect(recorder!.isRecording, isFalse);

    await tester.tap(find.text('START RECORDING'));
    await tester.pump();

    expect(recorder.isRecording, isTrue);

    recorder.recordNoteOn(note: 60, velocity: 0.8, voiceId: 1);
    await tester.pump();

    expect(find.textContaining('EVENTS'), findsWidgets);

    await tester.tap(find.text('STOP'));
    await tester.pump();

    expect(recorder.isRecording, isFalse);
    expect(recorder.lastRecording, isNotNull);
    expect(recorder.lastRecording!.events, isNotEmpty);

    await tester.tap(find.text('COPY JSON'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    engine.dispose();
  });
}
