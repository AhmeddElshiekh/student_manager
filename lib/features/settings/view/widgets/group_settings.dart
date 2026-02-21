import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nizam/features/settings/view/widgets/settings_card.dart';
import '../../view_model/settings_cubit.dart';

class GroupSettings extends StatelessWidget {
  const GroupSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SettingsCubit>();
    final state = cubit.state;

    return SettingsCard(
      title: 'إعدادات المجموعات',
      icon: Icons.tune_outlined,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: const Text('ساعات التداخل المسموح بها'),
          subtitle: Text('${state.timeConflictHours} ساعة'),
        ),
        Slider(
          value: state.timeConflictHours.toDouble(),
          min: 0,
          max: 4,
          divisions: 4,
          label: '${state.timeConflictHours} ساعة',
          onChanged: (v) => cubit.setTimeConflictHours(v.toInt()),
        ),
      ],
    );
  }
}
