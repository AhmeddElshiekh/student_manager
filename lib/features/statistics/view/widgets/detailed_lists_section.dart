import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'detailed_list_item.dart';

class DetailedListsSection extends StatelessWidget {
  const DetailedListsSection({
    super.key,
    required this.studentsPerClass,
    required this.studentsPerGroup,
    required this.revenuePerGroupDisplay,
  });

  final Map<String, int> studentsPerClass;
  final Map<String, int> studentsPerGroup;
  final Map<String, double> revenuePerGroupDisplay;

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
    final sortedClasses = studentsPerClass.keys.toList()..sort();
    final sortedGroups = studentsPerGroup.keys.toList()
      ..sort((a, b) {
        try {
          return _formatGroupDateTime(a).compareTo(_formatGroupDateTime(b));
        } catch (e) {
          return a.compareTo(b);
        }
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
          child: Center(
            child: Text(
              'قوائم تفصيلية',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (studentsPerClass.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('لا توجد بيانات للصفوف.'),
          ))
        else
          ...sortedClasses.map(
            (className) => DetailedListItem(
              title: className,
              subtitle: '${studentsPerClass[className]} طلاب',
              icon: Icons.class_outlined,
              color: theme.primaryColor,
            ),
          ),
        const SizedBox(height: 24),
        if (studentsPerGroup.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('لا توجد بيانات للمجموعات.'),
          ))
        else
          ...sortedGroups.map((groupString) {
            final revenue = revenuePerGroupDisplay[groupString] ?? 0.0;
            final subtitle =
                '${studentsPerGroup[groupString]} طلاب | إيرادات: ${revenue.toStringAsFixed(0)} جنيه';

            return DetailedListItem(
              title: _formatGroupDateTime(groupString),
              subtitle: subtitle,
              icon: Icons.groups_outlined,
              color: theme.colorScheme.secondary,
            );
          }),
      ],
    );
  }
}
