import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chart_card.dart';
import 'pie_chart_badge.dart';

class ChartsSection extends StatefulWidget {
  const ChartsSection({
    super.key,
    required this.monthlyRevenue,
    required this.studentsPerClass,
    required this.studentsPerGroup,
  });

  final Map<int, double> monthlyRevenue;
  final Map<String, int> studentsPerClass;
  final Map<String, int> studentsPerGroup;

  @override
  State<ChartsSection> createState() => _ChartsSectionState();
}

class _ChartsSectionState extends State<ChartsSection> {
  int pieClassTouchedIndex = -1;
  int pieGroupTouchedIndex = -1;

  String _formatGroupDateTime(String groupDateTimeString) {
    try {
      final DateTime dateTime = DateTime.parse(groupDateTimeString);
      return DateFormat('EEEE h:mm a', 'ar').format(dateTime);
    } catch (e) {
      return groupDateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'رسوم بيانية للإيرادات والطلاب',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        ChartCard(
          title: 'الإيرادات الشهرية (العام الحالي)',
          chart: SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: theme.colorScheme.secondary.withAlpha(204),
                  ),
                ),
                barGroups: widget.monthlyRevenue.entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: theme.primaryColor,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const monthNames = [
                          'ي',
                          'ف',
                          'م',
                          'أ',
                          'م',
                          'ي',
                          'ي',
                          'أ',
                          'س',
                          'أ',
                          'ن',
                          'د'
                        ];
                        if (value.toInt() > 0 &&
                            value.toInt() <= monthNames.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(monthNames[value.toInt() - 1],
                                style: theme.textTheme.bodySmall),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text('${value.toInt()}',
                            style: theme.textTheme.bodySmall);
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withAlpha(26),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: 'توزيع الطلاب حسب الصف',
          chart: SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        pieClassTouchedIndex = -1;
                        return;
                      }
                      pieClassTouchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildPieChartSections(
                    widget.studentsPerClass, theme, pieClassTouchedIndex,
                    isGroup: false),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: 'توزيع الطلاب حسب المجموعة',
          chart: SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        pieGroupTouchedIndex = -1;
                        return;
                      }
                      pieGroupTouchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildPieChartSections(
                  widget.studentsPerGroup.map((key, value) =>
                      MapEntry(_formatGroupDateTime(key), value)),
                  theme,
                  pieGroupTouchedIndex,
                  isGroup: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
      Map<String, int> data, ThemeData theme, int touchedIndex,
      {bool isGroup = false}) {
    final List<Color> colors = isGroup
        ? [
            theme.colorScheme.secondary,
            theme.colorScheme.secondary.withAlpha(179),
            theme.colorScheme.tertiary,
            theme.colorScheme.tertiary.withAlpha(179),
          ]
        : [
            theme.primaryColor,
            theme.primaryColor.withAlpha(179),
            theme.colorScheme.error,
            theme.colorScheme.error.withAlpha(179),
          ];

    if (data.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 1,
          title: '',
          radius: 60,
        )
      ];
    }

    final List<MapEntry<String, int>> indexedEntries = data.entries.toList();

    return indexedEntries.asMap().entries.map((mapEntry) {
      final int index = mapEntry.key;
      final MapEntry<String, int> entry = mapEntry.value;

      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 70.0 : 60.0;
      final color = colors[index % colors.length];

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        badgeWidget:
            isTouched ? PieChartBadge(entry.key, borderColor: color) : null,
        badgePositionPercentageOffset: 1,
      );
    }).toList();
  }
}
