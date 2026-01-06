import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studentmanager/features/user/view/widgets/manage_devices_dialog.dart';
import 'package:studentmanager/features/user/view_model/admin_cubit.dart';
import 'package:studentmanager/features/user/view_model/admin_state.dart';
import 'package:url_launcher/url_launcher.dart';

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user});

  final UserModel user;

  Future<void> _makePhoneCall(BuildContext context) async {
    if (user.phoneNumber.isEmpty || user.phoneNumber == 'رقم هاتف غير متاح') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم الهاتف غير متاح.')));
      return;
    }
    final uri = Uri(scheme: 'tel', path: user.phoneNumber);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تشغيل الاتصال.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(user.uid),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await _makePhoneCall(context);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(16)),
        child: const Row(children: [
          Icon(Icons.phone, color: Colors.white),
          SizedBox(width: 12),
          Text('اتصال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shadowColor: Colors.black.withAlpha(26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              _UserCardInfo(user: user),
              _UserCardActions(user: user),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCardInfo extends StatelessWidget {
  const _UserCardInfo({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool hasExceededDevices = user.deviceIds.length > user.maxDevices;

    return Expanded(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: user.isApproved ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26),
            child: Icon(user.isApproved ? Icons.check_circle : Icons.cancel, color: user.isApproved ? Colors.green : Colors.red, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user.email, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('الأجهزة: ${user.deviceIds.length}/${user.maxDevices}', style: theme.textTheme.bodySmall),
                    if (hasExceededDevices)
                      const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.warning, color: Colors.red, size: 16)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCardActions extends StatelessWidget {
  const _UserCardActions({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminCubit>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _showManageDevicesDialog(context, cubit, user),
          child: const Text('الأجهزة'),
        ),
        _MoreActionsMenu(user: user, cubit: cubit),
      ],
    );
  }
}

class _MoreActionsMenu extends StatelessWidget {
  const _MoreActionsMenu({required this.user, required this.cubit});
  final UserModel user;
  final AdminCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'toggle') {
          _confirmToggleApproval(context, cubit, user);
        } else if (value == 'set_devices') {
          _showSetMaxDevicesDialog(context, cubit, user);
        } else if (value == 'delete') {
          _confirmDeleteUser(context, cubit, user);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: Text(user.isApproved ? 'إلغاء تفعيل المستخدم' : 'تفعيل المستخدم'),
        ),
        PopupMenuItem(
          value: 'set_devices',
          child: const Text('تحديد عدد الأجهزة'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Text('حذف المستخدم', style: TextStyle(color: colorScheme.error)),
        ),
      ],
      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
    );
  }
}

Future<bool?> _showConfirmationDialog(BuildContext context, {required String title, required String content, bool isDestructive = false}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('تأكيد', style: TextStyle(color: isDestructive ? Theme.of(context).colorScheme.error : null)),
        ),
      ],
    ),
  );
}

void _confirmToggleApproval(BuildContext context, AdminCubit cubit, UserModel user) async {
  final confirm = await _showConfirmationDialog(
    context,
    title: user.isApproved ? 'إلغاء التفعيل' : 'تفعيل المستخدم',
    content: 'هل أنت متأكد من ${user.isApproved ? "إلغاء تفعيل" : "تفعيل"} المستخدم ${user.displayName}؟',
  );
  if (confirm == true) cubit.toggleApprovalStatus(user.uid, user.isApproved);
}

void _confirmDeleteUser(BuildContext context, AdminCubit cubit, UserModel user) async {
  final confirm = await _showConfirmationDialog(
    context,
    title: 'حذف المستخدم',
    content: 'هل أنت متأكد من حذف ${user.displayName}؟ لا يمكن التراجع عن هذا الإجراء.',
    isDestructive: true,
  );
  if (confirm == true) cubit.deleteUser(user.uid);
}

void _showSetMaxDevicesDialog(BuildContext context, AdminCubit cubit, UserModel user) {
  final controller = TextEditingController(text: user.maxDevices.toString());
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('تحديد عدد الأجهزة لـ ${user.displayName}'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'العدد الأقصى', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            final newMax = int.tryParse(controller.text);
            if (newMax != null) {
              cubit.setMaxDevices(user.uid, newMax);
              Navigator.pop(ctx);
            }
          },
          child: const Text('تحديث'),
        ),
      ],
    ),
  );
}

void _showManageDevicesDialog(BuildContext context, AdminCubit cubit, UserModel user) {
  showDialog(context: context, builder: (ctx) => ManageDevicesDialog(user: user, cubit: cubit));
}
