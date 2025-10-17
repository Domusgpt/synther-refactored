import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio_engine.dart';
import '../core/macro_controls.dart';
import '../core/parameter_registry.dart';

class MacroControlPanel extends StatefulWidget {
  const MacroControlPanel({super.key});

  @override
  State<MacroControlPanel> createState() => _MacroControlPanelState();
}

class _MacroControlPanelState extends State<MacroControlPanel> {
  final Map<String, double> _pendingValues = <String, double>{};
  final ParameterRegistry _registry = ParameterRegistry.instance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0B0F2D).withOpacity(0.95),
                const Color(0xFF040511).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFF00FF).withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAAFF66FF),
                blurRadius: 28,
                spreadRadius: -14,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Consumer<AudioEngine>(
            builder: (context, engine, _) {
              final macros = engine.macroDefinitions;
              final snapshots = engine.macroSnapshots;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Macro Controls',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colorScheme.secondary,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              macros.isEmpty
                                  ? 'Register macro definitions to expose expressive sweeps across presets and performances.'
                                  : 'Tweak macro sweeps live. Assignments update presets, the backend, and visualiser in sync.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close macro controls',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (macros.isEmpty)
                    _buildEmptyState()
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: macros.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final macro = macros[index];
                          final snapshot = snapshots.firstWhere(
                            (candidate) => candidate.definition.id == macro.id,
                            orElse: () => MacroSnapshot(definition: macro, value: macro.defaultValue),
                          );
                          final value = _pendingValues[macro.id] ?? snapshot.value;
                          return _buildMacroCard(context, engine, macro, value);
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (macros.isNotEmpty) _buildFooter(engine),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.tune, color: Colors.white54, size: 42),
            SizedBox(height: 12),
            Text(
              'No macro definitions registered',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Macros travel with presets – register them on the audio engine or preset library to reveal them here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard(
    BuildContext context,
    AudioEngine engine,
    MacroDefinition macro,
    double value,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        gradient: LinearGradient(
          colors: [
            const Color(0x33FF66FF),
            const Color(0x2200FFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      macro.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (macro.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          macro.description,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 1,
            divisions: 100,
            label: value.toStringAsFixed(2),
            onChanged: (next) {
              setState(() {
                _pendingValues[macro.id] = next;
              });
              engine.setMacroValue(macro.id, next);
            },
          ),
          if (macro.assignments.isEmpty)
            const Text(
              'No parameter assignments – use this macro for metadata or future routing.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            _buildAssignmentsList(macro),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList(MacroDefinition macro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignments',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        ...macro.assignments.map((assignment) {
          final descriptor = _registry.descriptorFor(assignment.parameterId);
          final name = descriptor?.name ?? assignment.parameterId;
          final min = descriptor?.range.denormalize(assignment.minNormalized) ?? assignment.minNormalized;
          final max = descriptor?.range.denormalize(assignment.maxNormalized) ?? assignment.maxNormalized;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                Text(
                  '${min.toStringAsFixed(2)} → ${max.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFooter(AudioEngine engine) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            setState(() => _pendingValues.clear());
            await engine.resetMacroValues();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Reset to defaults'),
        ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: () {
            setState(() => _pendingValues.clear());
            engine.clearMacros();
          },
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear macros'),
        ),
      ],
    );
  }
}
