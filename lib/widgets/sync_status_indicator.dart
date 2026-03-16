import 'package:flutter/material.dart';

import '../services/sync_service.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key, required this.syncService});

  final SyncService syncService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: syncService,
      builder: (BuildContext context, Widget? child) {
        final SyncStatus status = syncService.status;
        final _SyncStatusStyle style = _styleFor(status, context);

        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: style.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 14,
                height: 14,
                child: status == SyncStatus.syncing
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          style.foreground,
                        ),
                      )
                    : Icon(style.icon, size: 14, color: style.foreground),
              ),
              const SizedBox(width: 6),
              Text(
                style.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _SyncStatusStyle _styleFor(SyncStatus status, BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case SyncStatus.synced:
        return _SyncStatusStyle(
          label: 'synced',
          icon: Icons.cloud_done_outlined,
          foreground: colorScheme.primary,
          background: colorScheme.primaryContainer.withValues(alpha: 0.45),
          border: colorScheme.primary.withValues(alpha: 0.5),
        );
      case SyncStatus.syncing:
        return _SyncStatusStyle(
          label: 'syncing',
          icon: Icons.sync,
          foreground: colorScheme.tertiary,
          background: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
          border: colorScheme.tertiary.withValues(alpha: 0.5),
        );
      case SyncStatus.offline:
        return _SyncStatusStyle(
          label: 'offline',
          icon: Icons.cloud_off_outlined,
          foreground: colorScheme.error,
          background: colorScheme.errorContainer.withValues(alpha: 0.55),
          border: colorScheme.error.withValues(alpha: 0.55),
        );
    }
  }
}

class _SyncStatusStyle {
  const _SyncStatusStyle({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
}
