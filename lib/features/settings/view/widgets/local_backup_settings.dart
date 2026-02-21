import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nizam/features/settings/view/widgets/settings_card.dart';
import '../../view_model/settings_cubit.dart';

class LocalBackupSettings extends StatelessWidget {
  const LocalBackupSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    return SettingsCard(
      title: 'النسخ الاحتياطي المحلي',
      icon: Icons.save_alt_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.tonalIcon(onPressed: cubit.exportDataToJson, icon: const Icon(Icons.upload_file), label: const Text('تصدير البيانات (JSON)')),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final bool? overwrite = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('استيراد البيانات'),
                      content: const Text('هل تريد مسح البيانات الحالية أم دمجها؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('دمج')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('مسح واستبدال')),
                      ],
                    ),
                  );
                  if (overwrite != null && context.mounted) {
                    context.read<SettingsCubit>().importDataFromJson(overwrite: overwrite);
                  }
                },
                icon: const Icon(Icons.download_for_offline),
                label: const Text('استيراد البيانات (JSON)'),
              ),
            ],
          ),
        )
      ],
    );
  }
}
