import 'package:flutter/material.dart';
import '../models/vulnerability.dart';
import '../theme/app_theme.dart';

class SeverityIndicator extends StatelessWidget {
  final Severity severity;
  final bool showLabel;

  const SeverityIndicator({
    super.key,
    required this.severity,
    this.showLabel = true,
  });

  Color get _color {
    switch (severity) {
      case Severity.high:
        return AppTheme.severityHigh;
      case Severity.medium:
        return AppTheme.severityMedium;
      case Severity.low:
        return AppTheme.severityLow;
    }
  }

  String get _label {
    switch (severity) {
      case Severity.high:
        return 'High';
      case Severity.medium:
        return 'Medium';
      case Severity.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withAlpha(77), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              _label,
              style: TextStyle(
                color: _color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
