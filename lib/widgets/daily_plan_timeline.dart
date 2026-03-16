import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule_block.dart';
import '../state/planner_provider.dart';

class DailyPlanTimeline extends StatelessWidget {
  const DailyPlanTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final PlannerProvider provider = context.watch<PlannerProvider>();
    final List<ScheduleBlock> plan = provider.dailyPlan;

    if (plan.isEmpty) {
      return const Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No daily plan available yet.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plan.length,
      itemBuilder: (BuildContext context, int index) {
        final ScheduleBlock block = plan[index];
        final int durationMinutes = block.endTime
            .difference(block.startTime)
            .inMinutes;
        final bool isTaskBlock = block.type == ScheduleBlockTypes.task;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 210 + (index * 28).clamp(0, 300)),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double value, Widget? child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 14),
                child: child,
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isTaskBlock ? 0.08 : 0.04,
                  ),
                  blurRadius: isTaskBlock ? 10 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(
                isTaskBlock ? Icons.task_alt : Icons.free_breakfast,
              ),
              title: Text(
                isTaskBlock ? (block.task?.title ?? 'Task') : 'Break',
              ),
              subtitle: Text('$durationMinutes min'),
            ),
          ),
        );
      },
    );
  }
}
