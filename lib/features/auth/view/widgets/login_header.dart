import 'package:flutter/material.dart';
import 'package:nizam/core/theme/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Image.asset(
          'assets/images/removed_logo.png',
          width: 150,
          height: 150,
        ),
        Text('مرحبًا بك من جديد 👋', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'سجل دخولك للوصول إلى حسابك',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
