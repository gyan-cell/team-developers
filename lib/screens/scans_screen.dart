import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../providers/scan_provider.dart';
import '../widgets/animations.dart';

class ScansScreen extends StatelessWidget {
  const ScansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ScanProvider>().refreshActiveScans(),
          ),
        ],
      ),
      body: Consumer<ScanProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            );
          }

          if (provider.scans.isEmpty) {
            return FadeIn(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.radar,
                      size: 64,
                      color: AppTheme.textSecondary.withAlpha(100),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No scans yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add a target to start scanning',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshActiveScans(),
            color: AppTheme.accentCyan,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.scans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final scan = provider.scans[index];
                return SlideUp(
                  delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
                  child: _ScanCard(scan: scan),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final ScanResult scan;

  const _ScanCard({required this.scan});

  Color _getStatusColor(ScanStatus status) {
    switch (status) {
      case ScanStatus.queued:
        return AppTheme.textSecondary;
      case ScanStatus.started:
      case ScanStatus.running:
        return AppTheme.accentCyan;
      case ScanStatus.stopped:
        return AppTheme.severityMedium;
      case ScanStatus.completed:
        return AppTheme.severityLow;
      case ScanStatus.failed:
        return AppTheme.severityHigh;
    }
  }

  IconData _getStatusIcon(ScanStatus status) {
    switch (status) {
      case ScanStatus.queued:
        return Icons.hourglass_empty;
      case ScanStatus.started:
      case ScanStatus.running:
        return Icons.sync;
      case ScanStatus.stopped:
        return Icons.stop_circle_outlined;
      case ScanStatus.completed:
        return Icons.check_circle_outline;
      case ScanStatus.failed:
        return Icons.error_outline;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _showScanDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(scan.status).withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: scan.status.isActive
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _getStatusColor(scan.status),
                            ),
                          )
                        : Icon(
                            Icons.radar,
                            color: _getStatusColor(scan.status),
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scan.target,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${scan.scanId}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(scan.status).withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(scan.status),
                              color: _getStatusColor(scan.status),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              scan.status.name,
                              style: TextStyle(
                                color: _getStatusColor(scan.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(scan.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Action buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  // Summary badges
                  if (scan.summary.total > 0) ...[
                    _buildBadge(
                      'C',
                      scan.summary.critical,
                      const Color(0xFF9C27B0),
                    ),
                    const SizedBox(width: 6),
                    _buildBadge('H', scan.summary.high, AppTheme.severityHigh),
                    const SizedBox(width: 6),
                    _buildBadge(
                      'M',
                      scan.summary.medium,
                      AppTheme.severityMedium,
                    ),
                    const SizedBox(width: 6),
                    _buildBadge('L', scan.summary.low, AppTheme.severityLow),
                  ],
                  const Spacer(),
                  // Stop button (only for active scans)
                  if (scan.status.isActive)
                    SizedBox(
                      height: 32,
                      child: TextButton.icon(
                        onPressed: () => _stopScan(context),
                        icon: const Icon(Icons.stop, size: 16),
                        label: const Text('Stop'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.severityMedium,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  // Delete button (only for non-active scans)
                  if (!scan.status.isActive)
                    SizedBox(
                      height: 32,
                      child: TextButton.icon(
                        onPressed: () => _deleteScan(context),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.severityHigh,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
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

  Widget _buildBadge(String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label:$count',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _stopScan(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Stop Scan?'),
        content: const Text('Are you sure you want to stop this scan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ScanProvider>().stopScan(scan.scanId);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.severityMedium,
            ),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  void _deleteScan(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Delete Scan?'),
        content: const Text(
          'This will permanently remove the scan and its findings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ScanProvider>().removeScan(scan.scanId);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.severityHigh),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showScanDetails(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.accentCyan),
      ),
    );

    try {
      final results = await Future.wait([
        ApiService.getScanSummary(scan.scanId),
        ApiService.getScanFindingsGrouped(scan.scanId),
      ]);

      final summary = results[0] as ScanSummary;
      final groupedFindings = results[1] as Map<String, List<Finding>>;

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScanDetailScreen(
              scan: scan,
              summary: summary,
              groupedFindings: groupedFindings,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.severityHigh,
          ),
        );
      }
    }
  }
}

/// Scan detail screen with expandable severity sections
class ScanDetailScreen extends StatefulWidget {
  final ScanResult scan;
  final ScanSummary summary;
  final Map<String, List<Finding>> groupedFindings;

  const ScanDetailScreen({
    super.key,
    required this.scan,
    required this.summary,
    required this.groupedFindings,
  });

  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  late ScanSummary _summary;
  late Map<String, List<Finding>> _groupedFindings;
  bool _isRefreshing = false;

  final Map<Severity, bool> _expandedSections = {
    Severity.critical: true,
    Severity.high: true,
    Severity.medium: false,
    Severity.low: false,
    Severity.info: false,
  };

  @override
  void initState() {
    super.initState();
    _summary = widget.summary;
    _groupedFindings = widget.groupedFindings;
  }

  Future<void> _refreshFindings() async {
    setState(() => _isRefreshing = true);

    try {
      final results = await Future.wait([
        ApiService.getScanSummary(widget.scan.scanId),
        ApiService.getScanFindingsGrouped(widget.scan.scanId),
      ]);

      setState(() {
        _summary = results[0] as ScanSummary;
        _groupedFindings = results[1] as Map<String, List<Finding>>;
      });

      // Also update in provider
      if (mounted) {
        context.read<ScanProvider>().updateScanSummary(
          widget.scan.scanId,
          _summary,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.severityHigh,
          ),
        );
      }
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final findingsBySeverity = _groupFindingsBySeverity();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Findings'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentCyan,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshFindings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScanInfoCard(),
            const SizedBox(height: 16),
            _buildSummaryCard(),
            const SizedBox(height: 16),
            ..._buildSeveritySections(findingsBySeverity),
          ],
        ),
      ),
    );
  }

  Widget _buildScanInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.radar,
                color: AppTheme.accentCyan,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.scan.target,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan ID: ${widget.scan.scanId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Findings Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: ${_summary.total}',
                    style: const TextStyle(
                      color: AppTheme.accentPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSeverityCount(
                  'Critical',
                  _summary.critical,
                  _getSeverityColor(Severity.critical),
                ),
                const SizedBox(width: 6),
                _buildSeverityCount(
                  'High',
                  _summary.high,
                  _getSeverityColor(Severity.high),
                ),
                const SizedBox(width: 6),
                _buildSeverityCount(
                  'Medium',
                  _summary.medium,
                  _getSeverityColor(Severity.medium),
                ),
                const SizedBox(width: 6),
                _buildSeverityCount(
                  'Low',
                  _summary.low,
                  _getSeverityColor(Severity.low),
                ),
                const SizedBox(width: 6),
                _buildSeverityCount(
                  'Info',
                  _summary.info,
                  _getSeverityColor(Severity.info),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityCount(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.critical:
        return const Color(0xFF9C27B0);
      case Severity.high:
        return AppTheme.severityHigh;
      case Severity.medium:
        return AppTheme.severityMedium;
      case Severity.low:
        return AppTheme.severityLow;
      case Severity.info:
        return AppTheme.accentCyan;
    }
  }

  IconData _getSeverityIcon(Severity severity) {
    switch (severity) {
      case Severity.critical:
        return Icons.dangerous;
      case Severity.high:
        return Icons.warning_rounded;
      case Severity.medium:
        return Icons.error_outline;
      case Severity.low:
        return Icons.info_outline;
      case Severity.info:
        return Icons.help_outline;
    }
  }

  Map<Severity, List<Finding>> _groupFindingsBySeverity() {
    final Map<Severity, List<Finding>> grouped = {
      for (var s in Severity.values) s: [],
    };
    for (final findings in _groupedFindings.values) {
      for (final finding in findings) {
        grouped[finding.severity]!.add(finding);
      }
    }
    return grouped;
  }

  List<Widget> _buildSeveritySections(
    Map<Severity, List<Finding>> findingsBySeverity,
  ) {
    final sections = <Widget>[];

    for (final severity in Severity.values) {
      final findings = findingsBySeverity[severity] ?? [];
      if (findings.isEmpty) continue;

      final color = _getSeverityColor(severity);
      final label = severity.name[0].toUpperCase() + severity.name.substring(1);

      sections.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _expandedSections[severity] ?? false,
              onExpansionChanged: (expanded) =>
                  setState(() => _expandedSections[severity] = expanded),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getSeverityIcon(severity), color: color, size: 20),
              ),
              title: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${findings.length}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              children: findings
                  .map((f) => _buildFindingItem(f, color))
                  .toList(),
            ),
          ),
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: AppTheme.severityLow.withAlpha(128),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No findings detected',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildFindingItem(Finding finding, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  finding.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (finding.description != null &&
              finding.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                finding.description!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildTag(Icons.search, finding.scanner),
                if (finding.url.isNotEmpty)
                  _buildTag(Icons.link, finding.url, maxWidth: 150),
                if (finding.cwe != null && finding.cwe!.isNotEmpty)
                  _buildTag(Icons.security, 'CWE: ${finding.cwe}'),
                if (finding.cvss != null)
                  _buildTag(Icons.speed, 'CVSS: ${finding.cvss}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, {double? maxWidth}) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
