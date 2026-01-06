import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studentmanager/features/settings/view/widgets/settings_card.dart';
import '../../view_model/settings_cubit.dart';
import '../../view_model/settings_state.dart';

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SettingsCubit>();
    final state = cubit.state;

    return SettingsCard(
      title: 'وضع الثيم',
      icon: Icons.palette_outlined,
      children: [
        RadioListTile<AppThemeMode>(
          title: const Text('حسب النظام'),
          value: AppThemeMode.system,
          groupValue: state.themeMode,
          onChanged: (v) => cubit.setThemeMode(v!),
        ),
        RadioListTile<AppThemeMode>(
          title: const Text('فاتح'),
          value: AppThemeMode.light,
          groupValue: state.themeMode,
          onChanged: (v) => cubit.setThemeMode(v!),
        ),
        RadioListTile<AppThemeMode>(
          title: const Text('داكن'),
          value: AppThemeMode.dark,
          groupValue: state.themeMode,
          onChanged: (v) => cubit.setThemeMode(v!),
        ),
      ],
    );
  }
}
