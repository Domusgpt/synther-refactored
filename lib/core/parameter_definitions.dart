/// Shared parameter definitions for all platforms
/// These IDs must match the C++ implementation for native platforms

/// Parameter IDs used by the synth engine
class SynthParameterId {
  // Master parameters
  static const int masterVolume = 0;
  static const int masterMute = 1;
  
  // Oscillator parameters
  static const int oscillatorType = 2;
  static const int oscillatorVolume = 3;
  static const int oscillatorPanning = 4;
  static const int oscillatorFineTune = 5;
  static const int oscillatorPulseWidth = 6;

  // LFO parameters
  static const int lfoRate = 7;
  static const int lfoDepth = 8;

  // Filter parameters
  static const int filterCutoff = 10;
  static const int filterResonance = 11;
  static const int filterType = 12;
  
  // Envelope parameters
  static const int attackTime = 20;
  static const int decayTime = 21;
  static const int sustainLevel = 22;
  static const int releaseTime = 23;
  
  // Effect parameters
  static const int reverbMix = 30;
  static const int delayTime = 31;
  static const int delayFeedback = 32;
  static const int oscillatorBlend = 33;
  static const int oscillatorDetune = 34;
  static const int oscillatorSpread = 35;
  static const int distortionDrive = 36;
  static const int chorusRate = 37;
  static const int chorusDepth = 38;
  static const int glideTime = 39;

  // Performance parameters
  static const int pitchBendRange = 71;
  static const int modWheel = 72;
  static const int channelAftertouch = 73;
  static const int expression = 74;
  static const int sustainPedal = 75;

  // Granular parameters
  static const int granularActive = 40;
  static const int granularGrainRate = 41;
  static const int granularGrainDuration = 42;
  static const int granularPosition = 43;
  static const int granularPitch = 44;
  static const int granularAmplitude = 45;
  static const int granularPositionVariation = 46;
  static const int granularPitchVariation = 47;
  static const int granularDurationVariation = 48;
  static const int granularPan = 49;
  static const int granularPanVariation = 50;
  static const int granularWindowType = 51;
  static const int granularPositionVar = 52; // Alias
  static const int granularPitchVar = 53; // Alias
  static const int granularDurationVar = 54; // Alias
  static const int granularPanVar = 55; // Alias

  // Wavetable parameters
  static const int wavetablePosition = 60;

  // Microphone parameters
  static const int microphoneVolume = 70;

  // Arpeggiator parameters
  static const int arpeggiatorEnabled = 80;
  static const int arpeggiatorRate = 81;
  static const int arpeggiatorGate = 82;
  static const int arpeggiatorOctaves = 83;
  static const int arpeggiatorMode = 84;
  static const int arpeggiatorPattern = 85;
  static const int arpeggiatorSwing = 86;
  static const int arpeggiatorLatch = 87;
  static const int arpeggiatorTempoSync = 88;
  static const int arpeggiatorDivision = 89;

  // Transport parameters
  static const int transportTempo = 90;
  static const int transportRunning = 91;
  static const int transportTimeSignatureNumerator = 92;
  static const int transportTimeSignatureDenominator = 93;
}

/// Oscillator types
enum OscillatorType {
  sine(0),
  square(1),
  sawtooth(2),
  triangle(3),
  noise(4),
  pulse(5),
  wavetable(6),
  granular(7);
  
  final int value;
  const OscillatorType(this.value);
}

/// Filter types
enum FilterType {
  lowPass(0),
  highPass(1),
  bandPass(2),
  notch(3);
  
  final int value;
  const FilterType(this.value);
}

/// Grain window types
enum GrainWindowType {
  rectangular(0),
  hann(1),
  hamming(2),
  blackman(3);

  final int value;
  const GrainWindowType(this.value);
}

/// Arpeggiator playback directions.
enum ArpeggiatorMode {
  up(0),
  down(1),
  upDown(2),
  random(3),
  chord(4);

  final int value;
  const ArpeggiatorMode(this.value);
}

/// High-level patterns that can be applied on top of the playback direction.
enum ArpeggiatorPattern {
  asPlayed(0),
  majorTriad(1),
  minorTriad(2),
  octaves(3),
  fifths(4);

  final int value;
  const ArpeggiatorPattern(this.value);
}

/// Note division values used when the arpeggiator is tempo-synchronised.
enum ArpeggiatorDivision {
  whole(0, 4.0),
  half(1, 2.0),
  quarter(2, 1.0),
  eighth(3, 0.5),
  eighthTriplet(4, 1.0 / 3.0),
  sixteenth(5, 0.25),
  sixteenthTriplet(6, 1.0 / 6.0),
  thirtySecond(7, 0.125);

  final int value;
  final double beatsPerStep;
  const ArpeggiatorDivision(this.value, this.beatsPerStep);
}

/// XY Pad assignment options
enum XYPadAssignment {
  none,
  filterCutoff,
  filterResonance,
  oscillatorPitch,
  oscillatorFineTune,
  envelopeAttack,
  envelopeDecay,
  envelopeSustain,
  envelopeRelease,
  reverbMix,
  delayTime,
  delayFeedback,
  grainsRate,
  grainsDuration,
  grainsPosition,
  grainsPitch,
  grainsPan,
  wavetablePosition,
}

/// Scale types
enum ScalePreset {
  chromatic(0, 'Chromatic'),
  major(1, 'Major'),
  minor(2, 'Minor'),
  pentatonic(3, 'Pentatonic'),
  blues(4, 'Blues'),
  dorian(5, 'Dorian'),
  mixolydian(6, 'Mixolydian'),
  harmonicMinor(7, 'Harmonic Minor'),
  wholeStep(8, 'Whole Step'),
  diminished(9, 'Diminished');
  
  final int value;
  final String name;
  const ScalePreset(this.value, this.name);
}