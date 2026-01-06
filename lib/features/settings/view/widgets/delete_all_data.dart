import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../view_model/settings_cubit.dart';

class DeleteAllData extends StatelessWidget {
  const DeleteAllData({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('إعادة تعيين كل البيانات؟'),
                content: const Text(
                    'تحذير: هذا الإجراء لا يمكن التراجع عنه. سيتم حذف جميع الطلاب والمجموعات والفصول بشكل دائم من هذا الجهاز ومن النسخة الاحتياطية السحابية على جميع أجهزتك.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.read<SettingsCubit>().resetAllData();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                    child: const Text('نعم، أوافق على إعادة التعيين'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.delete_forever),
          label: const Text('إعادة تعيين جميع بيانات التطبيق'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
        ),
      ),
    );
  }
}
