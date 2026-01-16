import 'package:flutter/material.dart';
import '../models/scan.dart';
import '../theme/app_theme.dart';

class ScanActivityItem extends StatelessWidget {
  final Scan scan;
  final VoidCallback? onTap;

  const ScanActivityItem({super.key, required this.scan, this.onTap});

  Color get _statusColor {
    switch (scan.status) {
      case ScanStatus.running:
        return AppTheme.accentCyan;
      case ScanStatus.completed:
        return AppTheme.severityLow;
      case ScanStatus.failed:
        return AppTheme.severityHigh;
    }
  }

  String get _statusLabel {
    switch (scan.status) {
      case ScanStatus.running:
        return 'Running';
      case ScanStatus.completed:
        return 'Completed';
      case ScanStatus.failed:
        return 'Failed';
    }
  }

  IconData get _statusIcon {
    switch (scan.status) {
      case ScanStatus.running:
        return Icons.sync;
      case ScanStatus.completed:
        return Icons.check_circle_outline;
      case ScanStatus.failed:
        return Icons.error_outline;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.radar,
                  color: AppTheme.accentCyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.targetName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${scan.vulnerabilitiesFound} vulnerabilities found',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, color: _statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(scan.startTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
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
