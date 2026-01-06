import 'package:flutter/material.dart';
import 'package:studentmanager/core/theme/app_colors.dart';

class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.app_registration_rounded, size: 60, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('إنشاء حساب جديد', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'أدخل معلوماتك لإنشاء حساب جديد',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
