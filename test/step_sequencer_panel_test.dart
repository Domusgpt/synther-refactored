import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:synther_holographic_pro/core/audio_engine.dart';
import 'package:synther_holographic_pro/core/basic_audio_backend.dart';
import 'package:synther_holographic_pro/core/step_sequencer.dart';
import 'package:synther_holographic_pro/ui/step_sequencer_panel.dart';

void main() {
  testWidgets('StepSequencerPanel adds steps via footer control', (tester) async {
    final engine = AudioEngine(
      backend: BasicAudioBackend(),
      stepSequencer: StepSequencer(pattern: StepSequencerPattern.empty(length: 4)),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: engine,
        child: const MaterialApp(
          home: Scaffold(body: StepSequencerPanel()),
        ),
      ),
    );

    expect(engine.stepSequencer.pattern.length, 4);

    await tester.tap(find.widgetWithText(ElevatedButton, 'ADD STEP'));
    await tester.pumpAndSettle();

    expect(engine.stepSequencer.pattern.length, 5);
    expect(engine.stepSequencer.pattern.steps.last.rest, isTrue);

    engine.dispose();
  });
}
