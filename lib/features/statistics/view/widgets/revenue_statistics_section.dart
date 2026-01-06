import 'package:flutter/material.dart';
import 'statistic_card.dart';

class RevenueStatisticsSection extends StatelessWidget {
  const RevenueStatisticsSection({
    super.key,
    required this.totalCollectedRevenue,
    required this.todayRevenue,
    required this.last7DaysRevenue,
    required this.last30DaysRevenue,
    required this.currentYearRevenue,
  });

  final double totalCollectedRevenue;
  final double todayRevenue;
  final double last7DaysRevenue;
  final double last30DaysRevenue;
  final double currentYearRevenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String formatRevenue(double amount) {
      return '${amount.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} جنيه';
    }

    return Column(
      children: [
        const Divider(height: 32),
        StatisticCard(
          title: 'إجمالي الإيرادات المجمعة',
          value: formatRevenue(totalCollectedRevenue),
          icon: Icons.monetization_on_outlined,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatisticCard(
                title: 'إيرادات اليوم',
                value: formatRevenue(todayRevenue),
                icon: Icons.today,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatisticCard(
                title: 'إيرادات 7 أيام',
                value: formatRevenue(last7DaysRevenue),
                icon: Icons.calendar_view_week_outlined,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatisticCard(
                title: 'إيرادات 30 يوم',
                value: formatRevenue(last30DaysRevenue),
                icon: Icons.calendar_view_month_outlined,
                color: theme.colorScheme.primary.withAlpha(204),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatisticCard(
                title: 'إيرادات العام',
                value: formatRevenue(currentYearRevenue),
                icon: Icons.calendar_today_rounded,
                color: theme.colorScheme.secondary.withAlpha(204),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
