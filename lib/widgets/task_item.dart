import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../state/task_provider.dart';
import 'glass_card.dart';
import 'priority_badge.dart';

class TaskItem extends StatefulWidget {
  const TaskItem({
    super.key,
    required this.task,
    required this.onDelete,
    this.animationIndex = 0,
  });

  final Task task;
  final VoidCallback onDelete;
  final int animationIndex;

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  double _scale = 1;

  @override
  void didUpdateWidget(covariant TaskItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.task.isCompleted && widget.task.isCompleted) {
      setState(() {
        _scale = 1.04;
      });

      Future<void>.delayed(const Duration(milliseconds: 130), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _scale = 1;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Duration appearDuration = Duration(
      milliseconds: 180 + (widget.animationIndex * 20).clamp(0, 100),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: appearDuration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 16),
              child: child,
            ),
          ),
        );
      },
      child: GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shadowOpacity: widget.task.isCompleted ? 0.06 : null,
        onTap: () {},
        child: ListTile(
          leading: Checkbox(
            value: widget.task.isCompleted,
            onChanged: (_) =>
                context.read<TaskProvider>().toggleTask(widget.task),
          ),
          title: Text(
            widget.task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: widget.task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              color: widget.task.isCompleted
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
          subtitle: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: widget.task.isCompleted ? 0.55 : 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: PriorityBadge(priority: widget.task.priority),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: widget.onDelete,
            tooltip: 'Delete task',
          ),
        ),
      ),
    );
  }
}
