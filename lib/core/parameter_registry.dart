import 'dart:collection';

import 'parameter_models.dart';
import 'voice_allocator.dart';

/// Rich metadata describing how a synthesiser parameter behaves.
class ParameterDescriptor {
  const ParameterDescriptor({
    required this.name,
    required this.range,
    required this.visualizerTarget,
    this.bridgeAliases = const <String>[],
    this.extractionHints = const <String>[],
  });

  /// Canonical parameter name used within the audio engine.
  final String name;

  /// Numerical range and curve metadata for the parameter.
  final ParameterRange range;

  /// Identifier consumed by the visualiser bridge.
  final String visualizerTarget;

  /// Aliases that should mirror updates across the UI/audio bridge.
  final List<String> bridgeAliases;

  /// Additional keys accepted when parsing preset or JSON data.
  final List<String> extractionHints;

  /// Returns every recognised key for this parameter (canonical + aliases).
  Iterable<String> get allKeys sync* {
    yield name;
    for (final alias in bridgeAliases) {
      yield alias;
    }
    for (final hint in extractionHints) {
      yield hint;
    }
  }
}

/// Central registry that exposes canonical parameter metadata, alias lookups,
/// and helper utilities for synchronising data across systems.
class ParameterRegistry {
  ParameterRegistry._() {
    _register(
      ParameterDescriptor(
        name: 'masterVolume',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.75,
          curve: ParameterCurve.linear,
        ),
        visualizerTarget: 'brightness',
        bridgeAliases: const <String>['volume'],
        extractionHints: const <String>[
          'mastervolume',
          'amplevel',
          'ampvolume',
          'amp',
          'outputvolume',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'filterCutoff',
        range: const ParameterRange(
          min: 20,
          max: 20000,
          defaultValue: 1200,
          curve: ParameterCurve.exponential,
        ),
        visualizerTarget: 'geometryComplexity',
        bridgeAliases: const <String>['cutoff'],
        extractionHints: const <String>[
          'filtercutoff',
          'filtercut',
          'filterfrequency',
          'filterfreq',
          'cutoffhz',
          'filterhz',
          'filtercutoffhz',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'filterResonance',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.35,
          curve: ParameterCurve.linear,
        ),
        visualizerTarget: 'colorIntensity',
        bridgeAliases: const <String>['resonance'],
        extractionHints: const <String>[
          'filterresonance',
          'res',
          'filterres',
          'filterq',
          'q',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'oscillatorBlend',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.5,
        ),
        visualizerTarget: 'oscillatorBlend',
        bridgeAliases: const <String>['blend', 'oscBlend'],
        extractionHints: const <String>[
          'oscillatorblend',
          'oscblend',
          'oscillator.mix',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'oscillatorDetune',
        range: const ParameterRange(
          min: -12,
          max: 12,
          defaultValue: 0,
        ),
        visualizerTarget: 'oscillatorDetune',
        bridgeAliases: const <String>['detune', 'oscDetune'],
        extractionHints: const <String>[
          'oscillatordetune',
          'detunesemitones',
          'detuneamount',
          'oscillatordetunesemitones',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'oscillatorSpread',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.35,
        ),
        visualizerTarget: 'oscillatorSpread',
        bridgeAliases: const <String>['spread', 'unisonWidth'],
        extractionHints: const <String>[
          'oscillatorspread',
          'spread',
          'unisonwidth',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'attackTime',
        range: const ParameterRange(
          min: 0.001,
          max: 5,
          defaultValue: 0.02,
          curve: ParameterCurve.exponential,
        ),
        visualizerTarget: 'envelopeAttack',
        bridgeAliases: const <String>['attack'],
        extractionHints: const <String>[
          'attacktime',
          'envelopeattack',
          'envelopeattacktime',
          'adsrattack',
          'adsrattacktime',
          'envattack',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'decayTime',
        range: const ParameterRange(
          min: 0.001,
          max: 5,
          defaultValue: 0.2,
          curve: ParameterCurve.exponential,
        ),
        visualizerTarget: 'envelopeDecay',
        bridgeAliases: const <String>['decay'],
        extractionHints: const <String>[
          'decaytime',
          'envelopedecay',
          'envelopedecaytime',
          'adsrdecay',
          'adsrdecaytime',
          'envdecay',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'sustainLevel',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.7,
        ),
        visualizerTarget: 'envelopeSustain',
        extractionHints: const <String>[
          'sustainlevel',
          'sustain',
          'envelopesustain',
          'envelopesustainlevel',
          'adsrsustain',
          'adsrsustainlevel',
          'envsustain',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'releaseTime',
        range: const ParameterRange(
          min: 0.01,
          max: 10,
          defaultValue: 0.4,
          curve: ParameterCurve.exponential,
        ),
        visualizerTarget: 'envelopeRelease',
        bridgeAliases: const <String>['release'],
        extractionHints: const <String>[
          'releasetime',
          'enveloperelease',
          'envelopereleasetime',
          'adsrrelease',
          'adsrreleasetime',
          'envrelease',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'reverbMix',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.25,
        ),
        visualizerTarget: 'spaceSize',
        bridgeAliases: const <String>['reverb'],
        extractionHints: const <String>[
          'reverbmix',
          'fxreverb',
          'effectsreverbmix',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'delayTime',
        range: const ParameterRange(
          min: 0.01,
          max: 2,
          defaultValue: 0.25,
        ),
        visualizerTarget: 'delayTime',
        extractionHints: const <String>[
          'delaytime',
          'delay',
          'fxdelaytime',
          'effectsdelaytime',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'delayFeedback',
        range: const ParameterRange(
          min: 0,
          max: 0.95,
          defaultValue: 0.2,
        ),
        visualizerTarget: 'delayFeedback',
        extractionHints: const <String>[
          'delayfeedback',
          'feedback',
          'delayfb',
          'fxdelayfeedback',
          'effectsdelayfeedback',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'distortionDrive',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.25,
        ),
        visualizerTarget: 'distortionDrive',
        bridgeAliases: const <String>['drive', 'distortion'],
        extractionHints: const <String>[
          'distortiondrive',
          'distortionamount',
          'drive',
          'fxdrive',
          'effectsdrive',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'chorusRate',
        range: const ParameterRange(
          min: 0.05,
          max: 12,
          defaultValue: 1.2,
          curve: ParameterCurve.exponential,
        ),
        visualizerTarget: 'chorusRate',
        bridgeAliases: const <String>['chorusFrequency', 'chorusSpeed'],
        extractionHints: const <String>[
          'chorusrate',
          'chorusfreq',
          'chorusspeed',
          'chorusratehz',
          'fxchorusrate',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'chorusDepth',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.35,
        ),
        visualizerTarget: 'chorusDepth',
        bridgeAliases: const <String>['chorusMix', 'chorusAmount'],
        extractionHints: const <String>[
          'chorusdepth',
          'chorusmix',
          'chorusamount',
          'choruswet',
          'fxchorusmix',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'glideTime',
        range: const ParameterRange(
          min: 0,
          max: 5,
          defaultValue: 0.08,
          curve: ParameterCurve.exponential,
        ),
        visualizerTarget: 'portamentoProgress',
        bridgeAliases: const <String>['portamento', 'glide', 'slideTime'],
        extractionHints: const <String>[
          'glidetime',
          'glide_time',
          'glide_seconds',
          'portamentotime',
          'portamento',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'pitchBendRange',
        range: const ParameterRange(
          min: 1,
          max: 24,
          defaultValue: 2,
        ),
        visualizerTarget: 'pitchBendRange',
        bridgeAliases: const <String>['pitchBend', 'pitchWheelRange', 'pbRange'],
        extractionHints: const <String>[
          'pitchbendrange',
          'pitch_bend_range',
          'pitchwheel',
          'pitchwheelrange',
          'pitchrange',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'modWheel',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0,
        ),
        visualizerTarget: 'modWheel',
        bridgeAliases: const <String>['modulationWheel', 'modWheelAmount'],
        extractionHints: const <String>[
          'modwheel',
          'mod_wheel',
          'modulationwheel',
          'mw',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'channelAftertouch',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0,
        ),
        visualizerTarget: 'aftertouch',
        bridgeAliases:
            const <String>['aftertouch', 'channelPressure', 'pressure'],
        extractionHints: const <String>[
          'channelaftertouch',
          'channel_aftertouch',
          'aftertouch',
          'channelpressure',
          'channel_pressure',
          'pressure',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'expression',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 1,
        ),
        visualizerTarget: 'expression',
        bridgeAliases: const <String>['expressionPedal', 'expressionAmount'],
        extractionHints: const <String>[
          'expression',
          'expression_pedal',
          'expressionpedal',
          'exp',
          'expressionamount',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'sustainPedal',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0,
        ),
        visualizerTarget: 'sustain',
        bridgeAliases: const <String>['sustain', 'holdPedal', 'damperPedal'],
        extractionHints: const <String>[
          'sustainpedal',
          'sustain_pedal',
          'holdpedal',
          'damperpedal',
          'sustain',
          'hold',
          'damper',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'lfoRate',
        range: const ParameterRange(
          min: 0.05,
          max: 30,
          defaultValue: 2.0,
          curve: ParameterCurve.exponential,
        ),
        visualizerTarget: 'modulatorRate',
        bridgeAliases: const <String>['lfoFrequency', 'modulationRate'],
        extractionHints: const <String>[
          'lforate',
          'lfofreq',
          'lfospeed',
          'modrate',
          'modspeed',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'lfoDepth',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.5,
        ),
        visualizerTarget: 'modulatorDepth',
        bridgeAliases: const <String>['modDepth', 'lfoAmount'],
        extractionHints: const <String>[
          'lfodepth',
          'moddepth',
          'modamount',
          'modulationdepth',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'maxPolyphony',
        range: ParameterRange(
          min: 1,
          max: VoiceAllocator.hardVoiceCeiling.toDouble(),
          defaultValue: VoiceAllocator.defaultMaxVoices.toDouble(),
        ),
        visualizerTarget: 'polyphony',
        bridgeAliases: const <String>['polyphony', 'voices'],
        extractionHints: const <String>[
          'maxpolyphony',
          'maxvoices',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularActive',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0,
        ),
        visualizerTarget: 'granularActivation',
        bridgeAliases: const <String>['granularEnabled', 'granularOn'],
        extractionHints: const <String>[
          'granularactive',
          'granular.active',
          'grainactive',
          'granularon',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularGrainRate',
        range: const ParameterRange(
          min: 0.1,
          max: 100,
          defaultValue: 10,
          curve: ParameterCurve.exponential,
        ),
        visualizerTarget: 'granularDensity',
        bridgeAliases:
            const <String>['grainRate', 'granularRate', 'granularDensity'],
        extractionHints: const <String>[
          'granulargrainrate',
          'granular.grainrate',
          'grain_rate',
          'granulardensity',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularGrainDuration',
        range: const ParameterRange(
          min: 0.005,
          max: 1.0,
          defaultValue: 0.05,
          curve: ParameterCurve.exponential,
        ),
        visualizerTarget: 'granularDuration',
        bridgeAliases: const <String>['grainDuration', 'granularDuration'],
        extractionHints: const <String>[
          'granulargrainduration',
          'granular.grain_duration',
          'grainlength',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularPosition',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.2,
        ),
        visualizerTarget: 'granularPosition',
        bridgeAliases: const <String>['grainPosition', 'granularOffset'],
        extractionHints: const <String>[
          'granularposition',
          'granular.position',
          'grainpos',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularPitch',
        range: const ParameterRange(
          min: 0.25,
          max: 4.0,
          defaultValue: 1.0,
          curve: ParameterCurve.exponential,
        ),
        visualizerTarget: 'granularPitch',
        bridgeAliases: const <String>['grainPitch', 'granularPitchShift'],
        extractionHints: const <String>[
          'granularpitch',
          'granular.pitch',
          'grainpitch',
          'pitchshift',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularAmplitude',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.8,
        ),
        visualizerTarget: 'granularLevel',
        bridgeAliases: const <String>['grainLevel', 'granularLevel'],
        extractionHints: const <String>[
          'granularamplitude',
          'granular.amplitude',
          'grainamp',
          'grainvolume',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularPositionVariation',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.25,
        ),
        visualizerTarget: 'granularPositionVariance',
        bridgeAliases:
            const <String>['grainPositionVariation', 'granularPositionVar'],
        extractionHints: const <String>[
          'granularpositionvariation',
          'granular.position_variation',
          'grainpositionvar',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularPitchVariation',
        range: const ParameterRange(
          min: 0,
          max: 2,
          defaultValue: 0.15,
        ),
        visualizerTarget: 'granularPitchVariance',
        bridgeAliases:
            const <String>['grainPitchVariation', 'granularPitchVar'],
        extractionHints: const <String>[
          'granularpitchvariation',
          'granular.pitch_variation',
          'grainpitchvar',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularDurationVariation',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.12,
        ),
        visualizerTarget: 'granularDurationVariance',
        bridgeAliases:
            const <String>['grainDurationVariation', 'granularDurationVar'],
        extractionHints: const <String>[
          'granulardurationvariation',
          'granular.duration_variation',
          'graindurationvar',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularPan',
        range: const ParameterRange(
          min: -1,
          max: 1,
          defaultValue: 0,
        ),
        visualizerTarget: 'granularPan',
        bridgeAliases: const <String>['grainPan'],
        extractionHints: const <String>[
          'granularpan',
          'granular.pan',
          'grainpan',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularPanVariation',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.1,
        ),
        visualizerTarget: 'granularStereoVariance',
        bridgeAliases:
            const <String>['grainPanVariation', 'granularPanVar'],
        extractionHints: const <String>[
          'granularpanvariation',
          'granular.pan_variation',
          'grainpanvar',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'granularWindowType',
        range: const ParameterRange(
          min: 0,
          max: 3,
          defaultValue: 1,
        ),
        visualizerTarget: 'granularWindowShape',
        bridgeAliases: const <String>['grainWindow', 'granularWindow'],
        extractionHints: const <String>[
          'granularwindowtype',
          'granular.window',
          'grainwindow',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'wavetablePosition',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0.3,
        ),
        visualizerTarget: 'wavetablePosition',
        bridgeAliases: const <String>['tablePosition', 'wavetableIndex'],
        extractionHints: const <String>[
          'wavetableposition',
          'wavetable.position',
          'wavetablepos',
        ],
      ),
    );

    _register(
      ParameterDescriptor(
        name: 'microphoneVolume',
        range: const ParameterRange(
          min: 0,
          max: 1,
          defaultValue: 0,
        ),
        visualizerTarget: 'microphoneLevel',
        bridgeAliases: const <String>['micVolume', 'inputGain'],
        extractionHints: const <String>[
          'microphonevolume',
          'microphone.volume',
          'micgain',
          'inputvolume',
        ],
      ),
    );
  }

  static final ParameterRegistry instance = ParameterRegistry._();

  final Map<String, ParameterDescriptor> _descriptors =
      <String, ParameterDescriptor>{};
  final Map<String, String> _aliasLookup = <String, String>{};

  /// Exposes a read-only view of the registered descriptors.
  UnmodifiableMapView<String, ParameterDescriptor> get descriptors =>
      UnmodifiableMapView<String, ParameterDescriptor>(_descriptors);

  /// Returns every canonical parameter name.
  List<String> get canonicalNames => _descriptors.keys.toList(growable: false);

  /// Returns the canonical name for [key] if one is registered.
  String? canonicalName(String key) {
    return _aliasLookup[_normalise(key)];
  }

  /// Returns the descriptor for [key] whether a canonical or alias name is
  /// provided. Returns `null` for unknown parameters.
  ParameterDescriptor? descriptorFor(String key) {
    final canonical = canonicalName(key) ?? key;
    return _descriptors[canonical];
  }

  /// Returns the default value for [key] or `null` when unknown.
  double? defaultValue(String key) {
    return descriptorFor(key)?.range.defaultValue;
  }

  /// Canonicalises [values] to the engine parameter names, dropping unknown
  /// entries.
  Map<String, double> canonicalize(Map<String, double> values) {
    final canonical = <String, double>{};
    values.forEach((key, value) {
      final resolved = canonicalName(key);
      if (resolved != null) {
        final descriptor = descriptorFor(resolved);
        canonical[resolved] = descriptor?.range.clamp(value) ?? value;
      }
    });
    return canonical;
  }

  /// Expands [canonical] to include bridge aliases for downstream consumers.
  Map<String, double> expandWithAliases(Map<String, double> canonical) {
    final expanded = <String, double>{}..addAll(canonical);
    canonical.forEach((key, value) {
      final descriptor = descriptorFor(key);
      if (descriptor == null) {
        return;
      }
      for (final alias in descriptor.bridgeAliases) {
        expanded[alias] = value;
      }
    });
    return expanded;
  }

  /// Returns the bridge aliases for [canonical] or an empty list.
  List<String> bridgeAliases(String canonical) {
    return List<String>.unmodifiable(
      descriptorFor(canonical)?.bridgeAliases ?? const <String>[],
    );
  }

  /// Normalises [key] by stripping special characters and lower-casing it.
  static String normalizeKey(String key) => _normalise(key);

  void _register(ParameterDescriptor descriptor) {
    _descriptors[descriptor.name] = descriptor;
    for (final key in descriptor.allKeys) {
      _aliasLookup[_normalise(key)] = descriptor.name;
    }
  }

  static String _normalise(String key) {
    return key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
