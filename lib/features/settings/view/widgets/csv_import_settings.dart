import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studentmanager/core/navigation/app_router.dart';
import 'package:studentmanager/features/settings/view/google_sheet.dart';
import 'package:studentmanager/features/settings/view/widgets/conflict_resolution_dialog.dart';
import 'package:studentmanager/features/settings/view/widgets/settings_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../view_model/settings_cubit.dart';
import '../../view_model/settings_state.dart';

class CsvImportSettings extends StatelessWidget {
  const CsvImportSettings({super.key});

  Future<void> _launchGoogleFormTemplate(BuildContext context) async {
    final Uri url = Uri.parse('https://docs.google.com/forms/d/1TLOMHHDCM2QNvRjPZJbLxHsAwxEdTjfMl4Gn3e4xQ1o/copy');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الرابط!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) => previous.csvConflicts.isEmpty && current.csvConflicts.isNotEmpty,
      listener: (context, state) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return ConflictResolutionDialog(conflicts: state.csvConflicts);
          },
        );
      },
      child: SettingsCard(
        title: 'استيراد بيانات الطلاب',
        icon: Icons.people_alt_outlined,
        children: [
          BlocListener<SettingsCubit, SettingsState>(
            listener: (context, state) {
              if (state.successMessage?.isNotEmpty ?? false) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage!)));
                context.read<SettingsCubit>().clearMessages();
              } else if (state.errorMessage?.isNotEmpty ?? false) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
                context.read<SettingsCubit>().clearMessages();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('إنشاء ملف Google Sheet'),
                    subtitle: const Text('لجمع بيانات الطلاب بسهولة'),
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _launchGoogleFormTemplate(context),
                          icon: const Icon(Icons.launch),
                          tooltip: 'فتح الرابط',
                        ),
                        IconButton(
                          onPressed: () => AppRouter.pushWithScaleTransition(context, const GoogleSheetGuide()),
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'عرض التعليمات',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => context.read<SettingsCubit>().importStudentsFromCsv(),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('استيراد طلاب من ملف CSV'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
