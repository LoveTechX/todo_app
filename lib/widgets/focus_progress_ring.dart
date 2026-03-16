import 'dart:math' as math;

import 'package:flutter/material.dart';

class FocusProgressRing extends StatelessWidget {
  const FocusProgressRing({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    this.size = 180,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final double size;

  @override
  Widget build(BuildContext context) {
    final int clampedTotal = totalSeconds <= 0 ? 1 : totalSeconds;
    final double remainingFraction = (remainingSeconds / clampedTotal).clamp(
      0.0,
      1.0,
    );
    final double progress = (1 - remainingFraction).clamp(0.0, 1.0);
    final int minutes = remainingSeconds ~/ 60;
    final int seconds = remainingSeconds % 60;
    final String formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final Color ringColor = _colorForRemaining(remainingFraction, context);
    final Color trackColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.35);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: isRunning
              ? <BoxShadow>[
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: 10,
                color: trackColor,
              ),
            ),
            SizedBox(
              width: size,
              height: size,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                builder: (BuildContext context, double value, Widget? child) {
                  return Transform.rotate(
                    angle: -math.pi / 2,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      color: ringColor,
                      strokeCap: StrokeCap.round,
                    ),
                  );
                },
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(remainingFraction * 100).round()}% left',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForRemaining(double remainingFraction, BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    if (remainingFraction > 0.5) {
      return colorScheme.primary;
    }
    if (remainingFraction > 0.2) {
      return Colors.orange;
    }
    return colorScheme.error;
  }
}
