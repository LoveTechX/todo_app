import 'package:flutter/material.dart';

class FocusTimerCard extends StatelessWidget {
  const FocusTimerCard({
    super.key,
    required this.formattedTime,
    required this.durationMinutes,
    required this.isRunning,
    required this.onDurationChanged,
    required this.onStartPause,
    required this.onReset,
  });

  final String formattedTime;
  final int durationMinutes;
  final bool isRunning;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onStartPause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    const List<int> presets = <int>[15, 25, 45];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Focus Timer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Stay focused in short, uninterrupted sprints.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                formattedTime,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: presets
                  .map(
                    (int minutes) => ChoiceChip(
                      label: Text('$minutes min'),
                      selected: minutes == durationMinutes,
                      onSelected: isRunning
                          ? null
                          : (_) => onDurationChanged(minutes),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onStartPause,
                    icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(isRunning ? 'Pause' : 'Start'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
