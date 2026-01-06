import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../view_model/profile_state.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.state});
  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = state.firebaseUser!;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.person, size: 60, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(
              state.username ?? 'الاسم غير متاح',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              user.email ?? 'البريد الإلكتروني غير متاح',
              style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (state.isAdmin)
              Chip(
                avatar: const Icon(Icons.star, color: Colors.white, size: 16),
                label: const Text('مدير'),
                backgroundColor: colorScheme.primary,
                labelStyle: TextStyle(color: colorScheme.onPrimary),
              ),
            const SizedBox(height: 16),
            if (user.metadata.creationTime != null)
              Text(
                'تاريخ الانضمام: ${DateFormat('yyyy-MM-dd', 'ar').format(user.metadata.creationTime!)}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
