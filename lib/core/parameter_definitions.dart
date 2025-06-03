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