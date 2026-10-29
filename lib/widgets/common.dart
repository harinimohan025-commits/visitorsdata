import 'package:flutter/material.dart';

import '../models/visitor.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(count,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(title,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final VisitorStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Chip(
      label: Text(status.label),
      labelStyle:
          TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.14),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: cs.outline),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Shown when a refresh failed but older data is still on screen.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorBanner({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Could not refresh: $message',
              style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class VisitorCard extends StatelessWidget {
  final Visitor visitor;
  final bool showActions;
  final bool busy;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onQr;
  final VoidCallback? onCheck;

  const VisitorCard({
    super.key,
    required this.visitor,
    this.showActions = false,
    this.busy = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onQr,
    this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = visitor.status;
    final color = status.color;
    final initial =
        visitor.name.trim().isEmpty ? '?' : visitor.name.trim()[0].toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, showActions ? 4 : 12),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.14),
                    child: Text(initial,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visitor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(visitor.mobile,
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 13)),
                        if (visitor.email.isNotEmpty)
                          Text(visitor.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('${visitor.project}  •  ${visitor.type}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: cs.outline, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: status),
                ],
              ),
              if (showActions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (busy)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Show QR',
                      icon: const Icon(Icons.qr_code_2),
                      onPressed: busy ? null : onQr,
                    ),
                    IconButton(
                      tooltip: switch (status) {
                        VisitorStatus.registered => 'Check-in',
                        VisitorStatus.checkedIn => 'Check-out',
                        VisitorStatus.checkedOut => 'Visit completed',
                      },
                      icon: Icon(
                        switch (status) {
                          VisitorStatus.registered => Icons.login,
                          VisitorStatus.checkedIn => Icons.logout,
                          VisitorStatus.checkedOut => Icons.check_circle_outline,
                        },
                        color: switch (status) {
                          VisitorStatus.registered => Colors.green,
                          VisitorStatus.checkedIn => Colors.orange,
                          VisitorStatus.checkedOut => cs.outline,
                        },
                      ),
                      onPressed: (busy || status == VisitorStatus.checkedOut)
                          ? null
                          : onCheck,
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: busy ? null : onEdit,
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: Icon(Icons.delete_outline, color: cs.error),
                      onPressed: busy ? null : onDelete,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}