import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:studentmanager/features/settings/view/widgets/settings_card.dart';
import '../../view_model/settings_cubit.dart';

class FirebaseBackupSettings extends StatelessWidget {
  const FirebaseBackupSettings({super.key});

  Future<void> _performFirebaseBackup(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final bool? merge = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('النسخ الاحتياطي السحابي'),
        content: const Text('هل تريد دمج البيانات مع النسخة الموجودة، أم استبدالها بالكامل؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('دمج')),
          FilledButton(onPressed: () => Navigator.pop(context, false), child: const Text('استبدال')),
        ],
      ),
    );
    if (merge != null) cubit.performFirebaseBackup(merge: merge);
  }

  Future<void> _restoreFirebaseBackup(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final bool? merge = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة البيانات السحابية'),
        content: const Text('هل تريد دمج البيانات مع البيانات المحلية، أم مسحها واستبدالها؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('دمج')),
          FilledButton(onPressed: () => Navigator.pop(context, false), child: const Text('مسح واستبدال')),
        ],
      ),
    );
    if (merge != null) cubit.restoreFirebaseBackup(merge: merge);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SettingsCubit>();
    final state = cubit.state;

    return SettingsCard(
      title: 'النسخ الاحتياطي السحابي',
      icon: Icons.cloud_queue_outlined,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: const Icon(Icons.cloud_upload_outlined),
          title: const Text('نسخ احتياطي إلى Firebase'),
          subtitle: state.lastFirebaseBackupTime != null ? Text('آخر نسخ: ${DateFormat('yyyy-MM-dd HH:mm').format(state.lastFirebaseBackupTime!)}') : const Text('لا يوجد نسخ احتياطي متاح.'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _performFirebaseBackup(context),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: const Icon(Icons.cloud_download_outlined),
          title: const Text('استعادة البيانات من Firebase'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _restoreFirebaseBackup(context),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: const Text('تفعيل النسخ الاحتياطي التلقائي'),
          value: state.isAutoBackupEnabled,
          onChanged: (value) => cubit.toggleAutoBackup(value),
          secondary: const Icon(Icons.autorenew_outlined),
        ),
        if (state.isAutoBackupEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 0),
            child: DropdownButton<int>(
              isExpanded: true,
              value: state.autoBackupIntervalDays,
              items: const [
                DropdownMenuItem(value: 1440, child: Text('كل يوم')),
                DropdownMenuItem(value: 4320, child: Text('كل 3 أيام')),
                DropdownMenuItem(value: 10080, child: Text('كل أسبوع')),
              ],
              onChanged: (v) => cubit.setAutoBackupInterval(v!),
              underline: const SizedBox(),
            ),
          ),
      ],
    );
  }
}
