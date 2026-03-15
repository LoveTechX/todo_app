import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule_block.dart';
import '../state/todo_provider.dart';

class DailyPlanTimeline extends StatelessWidget {
  const DailyPlanTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final TodoProvider provider = context.watch<TodoProvider>();
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

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Icon(
              isTaskBlock ? Icons.task_alt : Icons.free_breakfast,
            ),
            title: Text(isTaskBlock ? (block.task?.title ?? 'Task') : 'Break'),
            subtitle: Text('$durationMinutes min'),
          ),
        );
      },
    );
  }
}
