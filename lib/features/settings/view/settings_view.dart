import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nizam/features/settings/view/widgets/auto_sync_info_card.dart';
import '../view_model/settings_cubit.dart';
import '../view_model/settings_state.dart';
import 'widgets/add_classes_settings.dart';
import 'widgets/csv_import_settings.dart';
import 'widgets/delete_all_data.dart';
import 'widgets/firebase_backup_settings.dart';
import 'widgets/group_settings.dart';
import 'widgets/local_backup_settings.dart';
import 'widgets/theme_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.status == SettingsStatus.loading) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('جاري تنفيذ العملية...')));
        }
        if (state.successMessage != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green));
          context.read<SettingsCubit>().clearMessages();
        }
        if (state.errorMessage != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: colorScheme.error));
          context.read<SettingsCubit>().clearMessages();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('الإعدادات'),
          centerTitle: true,
          backgroundColor: colorScheme.surfaceContainerLowest,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: const [
            ThemeSettings(),
            SizedBox(height: 16),
            AutoSyncInfoCard(), // <-- Card added here
            SizedBox(height: 16),
            AddClassesSettings(),
            SizedBox(height: 16),
            GroupSettings(),
            SizedBox(height: 16),
            FirebaseBackupSettings(),
            SizedBox(height: 16),
            LocalBackupSettings(),
            SizedBox(height: 16),
            CsvImportSettings(),
            SizedBox(height: 24),
            DeleteAllData(),
          ],
        ),
      ),
    );
  }
}
