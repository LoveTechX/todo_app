import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'focus_progress_ring.dart';
import 'glass_card.dart';

class FocusTimerCard extends StatefulWidget {
  const FocusTimerCard({
    super.key,
    required this.remainingSecondsListenable,
    required this.durationMinutes,
    required this.isRunning,
    required this.onDurationChanged,
    required this.onStartPause,
    required this.onReset,
  });

  final ValueListenable<int> remainingSecondsListenable;
  final int durationMinutes;
  final bool isRunning;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onStartPause;
  final VoidCallback onReset;

  @override
  State<FocusTimerCard> createState() => _FocusTimerCardState();
}

class _FocusTimerCardState extends State<FocusTimerCard> {
  Timer? _pulseTimer;
  bool _pulseOn = false;

  @override
  void initState() {
    super.initState();
    _syncPulseState();
  }

  @override
  void didUpdateWidget(covariant FocusTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRunning != widget.isRunning) {
      _syncPulseState();
    }
  }

  void _syncPulseState() {
    _pulseTimer?.cancel();

    if (!widget.isRunning) {
      setState(() {
        _pulseOn = false;
      });
      return;
    }

    _pulseOn = true;
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 260), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pulseOn = !_pulseOn;
      });
    });
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const List<int> presets = <int>[15, 25, 45];
    final Color glowColor = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          if (widget.isRunning)
            BoxShadow(
              color: glowColor.withValues(alpha: _pulseOn ? 0.2 : 0.1),
              blurRadius: _pulseOn ? 24 : 14,
              spreadRadius: _pulseOn ? 1 : 0,
            ),
        ],
      ),
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        shadowOpacity: widget.isRunning ? 0.18 : null,
        onTap: () {},
        child: ValueListenableBuilder<int>(
          valueListenable: widget.remainingSecondsListenable,
          builder: (BuildContext context, int remainingSeconds, Widget? _) {
            final int totalSeconds = (widget.durationMinutes * 60).clamp(
              1,
              86400,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Focus Timer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: widget.isRunning ? 0.75 : 1,
                  child: Text(
                    'Stay focused in short, uninterrupted sprints.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                FocusProgressRing(
                  remainingSeconds: remainingSeconds,
                  totalSeconds: totalSeconds,
                  isRunning: widget.isRunning,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: presets
                      .map(
                        (int minutes) => ChoiceChip(
                          label: Text('$minutes min'),
                          selected: minutes == widget.durationMinutes,
                          onSelected: widget.isRunning
                              ? null
                              : (_) => widget.onDurationChanged(minutes),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onStartPause,
                        icon: Icon(
                          widget.isRunning ? Icons.pause : Icons.play_arrow,
                        ),
                        label: Text(widget.isRunning ? 'Pause' : 'Start'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: widget.onReset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
