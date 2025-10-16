import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio_engine.dart';
import '../core/preset_setlist.dart';
import '../core/setlist_practice.dart';

class SetlistPracticePanel extends StatefulWidget {
  const SetlistPracticePanel({super.key});

  @override
  State<SetlistPracticePanel> createState() => _SetlistPracticePanelState();
}

class _SetlistPracticePanelState extends State<SetlistPracticePanel> {
  late double _defaultCueBeats;
  late double _defaultEntryBeats;
  late double _countInBeats;
  late bool _loop;

  @override
  void initState() {
    super.initState();
    final options = context.read<AudioEngine>().setlistPracticeOptions;
    _defaultCueBeats = options.defaultCueBeats;
    _defaultEntryBeats = options.defaultEntryBeats;
    _countInBeats = options.countInBeats;
    _loop = options.loop;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                const Color(0xFF080A1D).withOpacity(0.95),
                const Color(0xFF040511).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF7B68EE).withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x6600FFFF),
                blurRadius: 28,
                spreadRadius: -14,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Consumer<AudioEngine>(
            builder: (BuildContext context, AudioEngine engine, _) {
              final snapshot = engine.setlistPracticeSnapshot;
              final timeline = engine.setlistPracticeTimeline;
              final setlist = engine.activeSetlist;
              final hasTimeline = timeline.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Practice Timeline',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Plan rehearsals, adjust cue defaults, and step through setlists without leaving the vaporwave cockpit.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close practice panel',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PracticeOverviewCard(snapshot: snapshot, setlist: setlist),
                  const SizedBox(height: 20),
                  _buildOptionControls(context, engine),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _PracticeTimelineList(
                      timeline: timeline,
                      snapshot: snapshot,
                      setlist: setlist,
                      onJumpToEntry: (PresetSetlistEntry entry) =>
                          _jumpToEntry(context, engine, setlist, entry),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PracticeControls(
                    hasTimeline: hasTimeline,
                    onReset: () => _resetPractice(engine),
                    onAdvance: () => _stepPractice(context, engine, true),
                    onRetreat: () => _stepPractice(context, engine, false),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOptionControls(BuildContext context, AudioEngine engine) {
    final theme = Theme.of(context);

    void applyOptions() {
      engine.configureSetlistPractice(
        defaultCueBeats: _defaultCueBeats,
        defaultEntryBeats: _defaultEntryBeats,
        countInBeats: _countInBeats,
        loop: _loop,
        notify: true,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111327).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Cue & Count-in Defaults',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _LabeledSlider(
            label: 'Default cue beats',
            value: _defaultCueBeats,
            min: 0,
            max: 16,
            divisions: 32,
            suffix: 'beats',
            onChanged: (double value) {
              setState(() => _defaultCueBeats = value);
              applyOptions();
            },
          ),
          const SizedBox(height: 12),
          _LabeledSlider(
            label: 'Default entry length',
            value: _defaultEntryBeats,
            min: 4,
            max: 128,
            divisions: 124,
            suffix: 'beats',
            onChanged: (double value) {
              setState(() => _defaultEntryBeats = value);
              applyOptions();
            },
          ),
          const SizedBox(height: 12),
          _LabeledSlider(
            label: 'Count-in',
            value: _countInBeats,
            min: 0,
            max: 16,
            divisions: 32,
            suffix: 'beats',
            onChanged: (double value) {
              setState(() => _countInBeats = value);
              applyOptions();
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _loop,
            title: const Text(
              'Loop timeline',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Wrap to the first slot when advancing past the finale.',
              style: TextStyle(color: Colors.white60),
            ),
            activeColor: const Color(0xFF00FFFF),
            onChanged: (bool value) {
              setState(() => _loop = value);
              applyOptions();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _jumpToEntry(
    BuildContext context,
    AudioEngine engine,
    PresetSetlist? setlist,
    PresetSetlistEntry entry,
  ) async {
    if (setlist == null) {
      return;
    }
    final success = await engine.loadSetlistEntry(
      setlistId: setlist.id,
      entryId: entry.id,
      notify: true,
    );
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load ${entry.label ?? entry.id}'),
        ),
      );
    }
  }

  Future<void> _resetPractice(AudioEngine engine) async {
    engine.resetSetlistPractice();
  }

  Future<void> _stepPractice(
    BuildContext context,
    AudioEngine engine,
    bool forward,
  ) async {
    final success = forward
        ? await engine.advanceSetlistPractice()
        : await engine.retreatSetlistPractice();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(forward
              ? 'No further slots to advance to'
              : 'No previous slot available'),
        ),
      );
    }
  }
}

class _PracticeOverviewCard extends StatelessWidget {
  const _PracticeOverviewCard({
    required this.snapshot,
    required this.setlist,
  });

  final SetlistPracticeSnapshot? snapshot;
  final PresetSetlist? setlist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalEntries = snapshot?.totalEntries ?? setlist?.entries.length ?? 0;
    final currentIndex = snapshot?.currentIndex ?? -1;
    final activeLabel = snapshot?.current?.entry.label ??
        snapshot?.current?.entry.id ??
        'Unassigned';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141731).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            setlist?.name.toUpperCase() ?? 'NO SETLIST LOADED',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (setlist?.description != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              setlist!.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetricChip(
                label: 'Slots',
                value: totalEntries.toString(),
              ),
              _MetricChip(
                label: 'Current',
                value: currentIndex >= 0
                    ? '${currentIndex + 1} / $totalEntries'
                    : '—',
              ),
              _MetricChip(
                label: 'Loop count',
                value: (snapshot?.loopCount ?? 0).toString(),
              ),
              _MetricChip(
                label: 'Count-in',
                value:
                    snapshot != null ? '${snapshot.countInSeconds.toStringAsFixed(1)}s' : '—',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (snapshot?.current != null)
            Text(
              'Active slot · ${activeLabel.toUpperCase()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF00FFFF),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            )
          else
            const Text(
              'Load a setlist to initialise the practice timeline.',
              style: TextStyle(color: Colors.white60),
            ),
        ],
      ),
    );
  }
}

class _PracticeTimelineList extends StatelessWidget {
  const _PracticeTimelineList({
    required this.timeline,
    required this.snapshot,
    required this.setlist,
    required this.onJumpToEntry,
  });

  final List<SetlistPracticeSegment> timeline;
  final SetlistPracticeSnapshot? snapshot;
  final PresetSetlist? setlist;
  final ValueChanged<PresetSetlistEntry> onJumpToEntry;

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            setlist == null
                ? 'Load a setlist slot from the HUD to build a practice timeline.'
                : 'Add slots to ${setlist!.name} to generate a rehearsal timeline.',
            style: const TextStyle(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final currentId = snapshot?.current?.entry.id;

    return ListView.separated(
      itemCount: timeline.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final segment = timeline[index];
        final entry = segment.entry;
        final isActive = currentId == entry.id;
        final title = entry.label ?? 'Slot ${index + 1}';

        final subtitle = <String>[
          '${segment.durationBeats.toStringAsFixed(1)} beats',
          '${segment.durationSeconds.toStringAsFixed(1)}s at ${snapshot?.tempo.bpm.toStringAsFixed(1) ?? '—'} BPM',
          'Cue: ${segment.cueBeats.toStringAsFixed(1)} beats',
        ].join(' • ');

        return InkWell(
          onTap: setlist == null ? null : () => onJumpToEntry(entry),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isActive
                  ? const Color(0x3314FFEC)
                  : const Color(0x22161B3D),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF00FFFF).withOpacity(0.6)
                    : Colors.white24,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70),
                ),
                if (entry.notes != null && entry.notes!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    entry.notes!,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PracticeControls extends StatelessWidget {
  const _PracticeControls({
    required this.hasTimeline,
    required this.onReset,
    required this.onAdvance,
    required this.onRetreat,
  });

  final bool hasTimeline;
  final VoidCallback onReset;
  final VoidCallback onAdvance;
  final VoidCallback onRetreat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.tonal(
            onPressed: hasTimeline ? onRetreat : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Previous'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonal(
            onPressed: hasTimeline ? onReset : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Reset'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonal(
            onPressed: hasTimeline ? onAdvance : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} $suffix',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            inactiveTrackColor: Colors.white24,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: const Color(0x33202A5B),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
