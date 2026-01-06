import 'package:flutter/material.dart';
import 'package:studentmanager/features/settings/view/widgets/settings_card.dart';

class AutoSyncInfoCard extends StatelessWidget {
  const AutoSyncInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      icon: Icons.sync_alt,
      title: 'المزامنة التلقائية بين الأجهزة',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بياناتك الآن تتزامن تلقائياً عبر جميع أجهزتك التي تستخدم عليها نفس الحساب.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'كيف تعمل؟',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                  '• عند تعديل أي بيانات، يتم رفعها تلقائياً إلى السحابة.\n'
                  '• لجلب آخر التحديثات على جهاز آخر، فقط ضع التطبيق في الخلفية ثم افتحه مجدداً.'),
              const SizedBox(height: 12),
              Center(
                child: Icon(
                  Icons.phonelink_ring_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
