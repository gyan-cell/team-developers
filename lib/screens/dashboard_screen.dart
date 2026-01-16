import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vulnerability.dart' as vuln;
import '../theme/app_theme.dart';
import '../widgets/nav_drawer.dart';
import '../widgets/severity_chart.dart';
import '../widgets/summary_card.dart';
import '../widgets/animations.dart';
import '../providers/scan_provider.dart';
import '../services/api_service.dart';
import 'vulnerability_list_screen.dart';
import 'placeholder_screen.dart';
import 'targets_screen.dart';
import 'scans_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 0;
  int _refreshKey = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onNavItemSelected(int index) {
    setState(() => _selectedNavIndex = index);
    Navigator.pop(context);

    if (index == 0) return;

    final screens = [
      null, // Dashboard
      const TargetsScreen(),
      const ScansScreen(),
      const VulnerabilityListScreen(),
      PlaceholderScreen(title: 'Reports'),
      PlaceholderScreen(title: 'Settings'),
    ];

    if (screens[index] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screens[index]!),
      );
    }
  }

  void _navigateToVulnerabilities(vuln.Severity? severity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VulnerabilityListScreen(filterSeverity: severity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.severityHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.bgPrimary, width: 1),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.accentCyan, AppTheme.accentPurple],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentCyan.withAlpha(40),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      drawer: NavDrawer(
        selectedIndex: _selectedNavIndex,
        onItemSelected: _onNavItemSelected,
      ),
      body: Consumer<ScanProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.refreshActiveScans();
              _animController.reset();
              _animController.forward();
              setState(() => _refreshKey++);
            },
            color: AppTheme.accentCyan,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions Row
                      SlideUp(
                        delay: const Duration(milliseconds: 0),
                        child: _buildQuickActions(),
                      ),
                      const SizedBox(height: 20),

                      // Summary Cards
                      SlideUp(
                        delay: const Duration(milliseconds: 100),
                        child: _buildSummaryCards(isWide, provider),
                      ),
                      const SizedBox(height: 24),

                      if (isWide)
                        SlideUp(
                          delay: const Duration(milliseconds: 200),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildRecentScans(provider),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildSeverityChart(provider),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        SlideUp(
                          delay: const Duration(milliseconds: 200),
                          child: _buildSeverityChart(provider),
                        ),
                        const SizedBox(height: 24),
                        SlideUp(
                          delay: const Duration(milliseconds: 300),
                          child: _buildRecentScans(provider),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'New Scan',
            color: AppTheme.accentCyan,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TargetsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.radar,
            label: 'View Scans',
            color: AppTheme.accentPurple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScansScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color.withAlpha(30), color.withAlpha(15)],
        ),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isWide, ScanProvider provider) {
    final summary = provider.aggregatedSummary;

    if (isWide) {
      // Desktop: 6 cards in a row
      return GridView.count(
        crossAxisCount: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: _buildAllCards(provider, summary),
      );
    }

    // Mobile: 2 rows - first row with 2 cards, second row with 3 smaller cards
    return Column(
      children: [
        // First row: 2 cards (Total Targets, Active Scans)
        SizedBox(
          height: 130,
          child: Row(
            children: [
              Expanded(
                child: _buildCompactCard(
                  icon: Icons.track_changes,
                  title: 'Total Targets',
                  value: '${provider.totalScans}',
                  color: AppTheme.accentCyan,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TargetsScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactCard(
                  icon: Icons.radar,
                  title: 'Active Scans',
                  value: '${provider.activeScans}',
                  color: AppTheme.accentPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScansScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Second row: 3 risk cards (High, Medium, Low) - smaller height
        SizedBox(
          height: 90,
          child: Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  icon: Icons.warning_rounded,
                  title: 'High',
                  value: '${summary.critical + summary.high}',
                  color: AppTheme.severityHigh,
                  onTap: () => _navigateToVulnerabilities(vuln.Severity.high),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniCard(
                  icon: Icons.error_outline,
                  title: 'Medium',
                  value: '${summary.medium}',
                  color: AppTheme.severityMedium,
                  onTap: () => _navigateToVulnerabilities(vuln.Severity.medium),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniCard(
                  icon: Icons.info_outline,
                  title: 'Low',
                  value: '${summary.low}',
                  color: AppTheme.severityLow,
                  onTap: () => _navigateToVulnerabilities(vuln.Severity.low),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final numValue = int.tryParse(value) ?? 0;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final scaleAnim = CurvedAnimation(
          parent: _animController,
          curve: Curves.easeOutBack,
        );
        return Transform.scale(
          scale: 0.8 + 0.2 * scaleAnim.value,
          child: Opacity(
            opacity: _animController.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.bgCard,
                border: Border.all(color: color.withAlpha(30)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const Spacer(),
                        TweenAnimationBuilder<int>(
                          key: ValueKey('$title-$_refreshKey'),
                          tween: IntTween(begin: 0, end: numValue),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, animValue, child) {
                            return Text(
                              '$animValue',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final numValue = int.tryParse(value) ?? 0;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final scaleAnim = CurvedAnimation(
          parent: _animController,
          curve: Curves.easeOutBack,
        );
        return Transform.scale(
          scale: 0.8 + 0.2 * scaleAnim.value,
          child: Opacity(
            opacity: _animController.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.bgCard,
                border: Border.all(color: color.withAlpha(30)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TweenAnimationBuilder<int>(
                                key: ValueKey('mini-$title-$_refreshKey'),
                                tween: IntTween(begin: 0, end: numValue),
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOutCubic,
                                builder: (context, animValue, child) {
                                  return Text(
                                    '$animValue',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  );
                                },
                              ),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAllCards(ScanProvider provider, ScanSummary summary) {
    return [
      SummaryCard(
        icon: Icons.track_changes,
        title: 'Total Targets',
        value: '${provider.totalScans}',
        accentColor: AppTheme.accentCyan,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TargetsScreen()),
        ),
      ),
      SummaryCard(
        icon: Icons.radar,
        title: 'Active Scans',
        value: '${provider.activeScans}',
        accentColor: AppTheme.accentPurple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScansScreen()),
        ),
      ),
      SummaryCard(
        icon: Icons.dangerous,
        title: 'Critical',
        value: '${summary.critical}',
        accentColor: const Color(0xFF9C27B0),
        onTap: () => _navigateToVulnerabilities(vuln.Severity.high),
      ),
      SummaryCard(
        icon: Icons.warning_rounded,
        title: 'High Risk',
        value: '${summary.high}',
        accentColor: AppTheme.severityHigh,
        onTap: () => _navigateToVulnerabilities(vuln.Severity.high),
      ),
      SummaryCard(
        icon: Icons.error_outline,
        title: 'Medium Risk',
        value: '${summary.medium}',
        accentColor: AppTheme.severityMedium,
        onTap: () => _navigateToVulnerabilities(vuln.Severity.medium),
      ),
      SummaryCard(
        icon: Icons.info_outline,
        title: 'Low Risk',
        value: '${summary.low}',
        accentColor: AppTheme.severityLow,
        onTap: () => _navigateToVulnerabilities(vuln.Severity.low),
      ),
    ];
  }

  Widget _buildSeverityChart(ScanProvider provider) {
    final summary = provider.aggregatedSummary;
    return SeverityChart(
      key: ValueKey(_refreshKey),
      criticalCount: summary.critical,
      highCount: summary.high,
      mediumCount: summary.medium,
      lowCount: summary.low + summary.info,
    );
  }

  Widget _buildRecentScans(ScanProvider provider) {
    final recentScans = provider.scans.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.bgCard, AppTheme.bgCard.withAlpha(200)],
        ),
        border: Border.all(color: AppTheme.border.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history,
                        color: AppTheme.accentCyan,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScansScreen()),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentScans.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentScans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _buildScanActivityCard(recentScans[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.radar,
                size: 32,
                color: AppTheme.accentCyan.withAlpha(100),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No scans yet',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TargetsScreen()),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Start a Scan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanActivityCard(ScanResult scan) {
    final statusConfig = _getStatusConfig(scan.status);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgPrimary.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withAlpha(30)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScansScreen()),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Status indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusConfig.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusConfig.color.withAlpha(40)),
                  ),
                  child: scan.status.isActive
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: statusConfig.color,
                          ),
                        )
                      : Icon(
                          statusConfig.icon,
                          color: statusConfig.color,
                          size: 18,
                        ),
                ),
                const SizedBox(width: 12),
                // Scan info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan.target,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(scan.createdAt),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Summary badges
                if (scan.summary.total > 0) ...[
                  _buildMicroBadge(
                    scan.summary.critical + scan.summary.high,
                    AppTheme.severityHigh,
                  ),
                  const SizedBox(width: 4),
                  _buildMicroBadge(
                    scan.summary.medium,
                    AppTheme.severityMedium,
                  ),
                  const SizedBox(width: 4),
                  _buildMicroBadge(scan.summary.low, AppTheme.severityLow),
                  const SizedBox(width: 8),
                ],
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusConfig.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusConfig.color.withAlpha(40)),
                  ),
                  child: Text(
                    scan.status.name,
                    style: TextStyle(
                      color: statusConfig.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({Color color, IconData icon}) _getStatusConfig(ScanStatus status) {
    switch (status) {
      case ScanStatus.queued:
        return (color: AppTheme.textSecondary, icon: Icons.hourglass_empty);
      case ScanStatus.started:
      case ScanStatus.running:
        return (color: AppTheme.accentCyan, icon: Icons.sync);
      case ScanStatus.stopped:
        return (
          color: AppTheme.severityMedium,
          icon: Icons.stop_circle_outlined,
        );
      case ScanStatus.completed:
        return (color: AppTheme.severityLow, icon: Icons.check_circle_outline);
      case ScanStatus.failed:
        return (color: AppTheme.severityHigh, icon: Icons.error_outline);
    }
  }

  Widget _buildMicroBadge(int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
