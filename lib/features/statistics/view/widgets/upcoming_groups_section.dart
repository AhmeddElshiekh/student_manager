import 'package:flutter/material.dart';
import 'package:nizam/models/group_details_model.dart';

class UpcomingGroupsSection extends StatelessWidget {
  const UpcomingGroupsSection({
    super.key,
    required this.upcomingGroups,
    required this.studentsPerGroup,
  });

  final List<GroupDetailsModel> upcomingGroups;
  final Map<String, int> studentsPerGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المجموعات القادمة',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (upcomingGroups.isEmpty)
          Card(
            elevation: 0,
            color: theme.colorScheme.surface.withAlpha(128),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('لا توجد مجموعات قادمة خلال الأيام السبعة القادمة.'),
              ),
            ),
          )
        else
          ...upcomingGroups.take(5).map((group) {
            final studentCountInGroup = studentsPerGroup[group.groupDateTimeString] ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.event_available, color: theme.colorScheme.secondary),
                title: Text(
                  '${group.className} - ${group.groupDateTimeString}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('عدد الطلاب: $studentCountInGroup'),
              ),
            );
          }),
      ],
    );
  }
}
