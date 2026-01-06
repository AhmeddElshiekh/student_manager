import 'package:flutter/material.dart';
import 'package:studentmanager/core/theme/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.school_rounded, size: 60, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('مرحبًا بك من جديد 👋', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'سجل دخولك للوصول إلى حسابك',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
