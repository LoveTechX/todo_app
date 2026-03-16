import 'package:flutter/material.dart';

class FocusBarPoint {
  const FocusBarPoint({required this.label, required this.minutes});

  final String label;
  final int minutes;
}

class FocusChart extends StatelessWidget {
  const FocusChart({super.key, required this.points});

  final List<FocusBarPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No focus data this week yet.')),
      );
    }

    final int maxMinutes = points
        .map((FocusBarPoint point) => point.minutes)
        .fold<int>(
          0,
          (int maxValue, int value) => value > maxValue ? value : maxValue,
        );

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((FocusBarPoint point) {
          final double ratio = maxMinutes == 0 ? 0 : point.minutes / maxMinutes;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${point.minutes}m',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    height: 110 * ratio + 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    point.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
