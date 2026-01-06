import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/app_router.dart';
import '../../view_model/profile_cubit.dart';
import '../admin_page_view.dart';
import '../user_guide_view.dart';

class ActionButtonsList extends StatelessWidget {
  const ActionButtonsList({required this.isAdmin});
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAdmin)
          _ActionButton(
            label: 'لوحة تحكم المدير',
            icon: Icons.admin_panel_settings_rounded,
            color: Theme.of(context).colorScheme.primary,
            onPressed: () => AppRouter.push(context, const AdminPage()),
          ),
        _ActionButton(
          label: 'إرسال ملاحظات',
          icon: Icons.feedback_rounded,
          onPressed: () => cubit.launchEmail(),
        ),
        _ActionButton(
          label: 'دليل الاستخدام',
          icon: Icons.help_outline_rounded,
          onPressed: () => AppRouter.pushWithSlideTransition(context, const UserGuideView()),
        ),
        _ActionButton(
          label: 'إعادة تعيين كلمة المرور',
          icon: Icons.lock_reset_rounded,
          onPressed: () => _confirmResetPassword(context, cubit),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        _ActionButton(
          label: 'تسجيل الخروج',
          icon: Icons.logout_rounded,
          color: Theme.of(context).colorScheme.error,
          onPressed: () => _confirmSignOut(context, cubit),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, ProfileCubit cubit) async {
    final confirm = await _showConfirmationDialog(
      context,
      title: 'تأكيد تسجيل الخروج',
      content: 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
    );
    if (confirm == true) {
      cubit.signOut();
    }
  }

  Future<void> _confirmResetPassword(BuildContext context, ProfileCubit cubit) async {
    final email = context.read<ProfileCubit>().state.firebaseUser?.email;
    if (email == null) return;

    final confirm = await _showConfirmationDialog(
      context,
      title: 'إعادة تعيين كلمة المرور',
      content: 'سيتم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني:\n$email',
    );
    if (confirm == true) {
      cubit.resetPassword();
    }
  }

  Future<bool?> _showConfirmationDialog(BuildContext context, {required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
        ],
      ),
    );
  }
}
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: color ?? theme.colorScheme.primary,
      backgroundColor: color?.withAlpha(26) ?? theme.colorScheme.primary.withAlpha(26),
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: buttonStyle,
      ),
    );
  }
}