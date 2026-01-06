import 'package:flutter/material.dart';
import 'statistic_card.dart';

class MainStatisticsSection extends StatelessWidget {
  const MainStatisticsSection({
    super.key,
    required this.totalStudents,
    required this.paidStudentsCount,
    required this.unpaidStudentsCount,
    required this.expiringPaymentsSoon,
  });

  final int totalStudents;
  final int paidStudentsCount;
  final int unpaidStudentsCount;
  final int expiringPaymentsSoon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        StatisticCard(
          title: 'إجمالي الطلاب',
          value: totalStudents.toString(),
          icon: Icons.people_outline,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatisticCard(
                title: 'مدفوع حالياً',
                value: paidStudentsCount.toString(),
                icon: Icons.check_circle_outline,
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatisticCard(
                title: 'غير مدفوع حالياً',
                value: unpaidStudentsCount.toString(),
                icon: Icons.highlight_off,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StatisticCard(
          title: 'دفعات ستنتهي قريباً (خلال 24 ساعة)',
          value: expiringPaymentsSoon.toString(),
          icon: Icons.timer_outlined,
          color: Colors.orange.shade700,
        ),
      ],
    );
  }
}