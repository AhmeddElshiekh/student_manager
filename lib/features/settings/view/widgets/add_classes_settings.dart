import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studentmanager/features/settings/view/widgets/settings_card.dart';
import '../../view_model/settings_cubit.dart';

class AddClassesSettings extends StatelessWidget {
  const AddClassesSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    return SettingsCard(
      title: 'إضافة صفوف جاهزة',
      icon: Icons.library_add_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(onPressed: () => cubit.addPredefinedClasses('ابتدائي'), icon: const Icon(Icons.looks_one), label: const Text('ابتدائي')),
              FilledButton.tonalIcon(onPressed: () => cubit.addPredefinedClasses('إعدادي'), icon: const Icon(Icons.looks_two), label: const Text('إعدادي')),
              FilledButton.tonalIcon(onPressed: () => cubit.addPredefinedClasses('ثانوي'), icon: const Icon(Icons.looks_3), label: const Text('ثانوي')),
            ],
          ),
        ),
      ],
    );
  }
}
