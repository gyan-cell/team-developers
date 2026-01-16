import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SeverityChart extends StatefulWidget {
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final int? criticalCount;

  const SeverityChart({
    super.key,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    this.criticalCount,
  });

  @override
  State<SeverityChart> createState() => _SeverityChartState();
}

class _SeverityChartState extends State<SeverityChart>
    with SingleTickerProviderStateMixin {
  int touchedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(SeverityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Replay animation when data changes
    if (oldWidget.highCount != widget.highCount ||
        oldWidget.mediumCount != widget.mediumCount ||
        oldWidget.lowCount != widget.lowCount ||
        oldWidget.criticalCount != widget.criticalCount) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total =
        (widget.criticalCount ?? 0) +
        widget.highCount +
        widget.mediumCount +
        widget.lowCount;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.bgCard, AppTheme.bgCard.withAlpha(200)],
        ),
        border: Border.all(color: AppTheme.border.withAlpha(50), width: 1),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vulnerability Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animation.value,
                      child: Opacity(
                        opacity: _animation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPurple.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.accentPurple.withAlpha(40),
                            ),
                          ),
                          child: Text(
                            'Total: $total',
                            style: TextStyle(
                              color: AppTheme.accentPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 350;

                if (isNarrow) {
                  return Column(
                    children: [
                      SizedBox(
                        height: 180,
                        width: 180,
                        child: _buildAnimatedPieChart(total),
                      ),
                      const SizedBox(height: 24),
                      _buildAnimatedLegend(total),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 180,
                      width: 180,
                      child: _buildAnimatedPieChart(total),
                    ),
                    const SizedBox(width: 24),
                    Expanded(child: _buildAnimatedLegend(total)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedPieChart(int total) {
    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 48,
              color: AppTheme.severityLow.withAlpha(100),
            ),
            const SizedBox(height: 8),
            const Text(
              'No vulnerabilities',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + 0.5 * _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 4,
                centerSpaceRadius: 45 * _animation.value,
                sections: _buildAnimatedSections(total),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLegend(int total) {
    final items = <Widget>[];

    if (widget.criticalCount != null && widget.criticalCount! > 0) {
      items.add(
        _buildAnimatedLegendItem(
          'Critical',
          widget.criticalCount!,
          const Color(0xFF9C27B0),
          total,
          0,
        ),
      );
      items.add(const SizedBox(height: 12));
    }

    items.addAll([
      _buildAnimatedLegendItem(
        'High Risk',
        widget.highCount,
        AppTheme.severityHigh,
        total,
        1,
      ),
      const SizedBox(height: 12),
      _buildAnimatedLegendItem(
        'Medium Risk',
        widget.mediumCount,
        AppTheme.severityMedium,
        total,
        2,
      ),
      const SizedBox(height: 12),
      _buildAnimatedLegendItem(
        'Low Risk',
        widget.lowCount,
        AppTheme.severityLow,
        total,
        3,
      ),
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }

  List<PieChartSectionData> _buildAnimatedSections(int total) {
    final sections = <PieChartSectionData>[];
    int index = 0;

    // Animate radius from 0 to target
    final animatedRadius = 35 * _animation.value;
    final touchedRadius = 45 * _animation.value;

    if (widget.criticalCount != null && widget.criticalCount! > 0) {
      sections.add(
        PieChartSectionData(
          color: const Color(0xFF9C27B0),
          value: (widget.criticalCount! * _animation.value).toDouble(),
          title: touchedIndex == index ? '${widget.criticalCount}' : '',
          radius: touchedIndex == index ? touchedRadius : animatedRadius,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    }

    sections.addAll([
      PieChartSectionData(
        color: AppTheme.severityHigh,
        value: (widget.highCount * _animation.value).toDouble(),
        title: touchedIndex == index ? '${widget.highCount}' : '',
        radius: touchedIndex == index ? touchedRadius : animatedRadius,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: AppTheme.severityMedium,
        value: (widget.mediumCount * _animation.value).toDouble(),
        title: touchedIndex == index + 1 ? '${widget.mediumCount}' : '',
        radius: touchedIndex == index + 1 ? touchedRadius : animatedRadius,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: AppTheme.severityLow,
        value: (widget.lowCount * _animation.value).toDouble(),
        title: touchedIndex == index + 2 ? '${widget.lowCount}' : '',
        radius: touchedIndex == index + 2 ? touchedRadius : animatedRadius,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ]);

    return sections;
  }

  Widget _buildAnimatedLegendItem(
    String label,
    int count,
    Color color,
    int total,
    int index,
  ) {
    final percentage = total > 0
        ? (count / total * 100).toStringAsFixed(1)
        : '0';
    final delay = index * 0.15;
    final itemAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          delay,
          (delay + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - itemAnimation.value), 0),
          child: Opacity(
            opacity: itemAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withAlpha(30)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(60),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: count),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Text(
                        '$value',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($percentage%)',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
