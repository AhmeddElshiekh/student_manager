import 'package:flutter/material.dart';
import 'package:nizam/features/user/view_model/admin_cubit.dart';
import 'package:nizam/features/user/view_model/admin_state.dart';

class ManageDevicesDialog extends StatefulWidget {
  const ManageDevicesDialog({super.key, required this.user, required this.cubit});
  final UserModel user;
  final AdminCubit cubit;

  @override
  State<ManageDevicesDialog> createState() => _ManageDevicesDialogState();
}

class _ManageDevicesDialogState extends State<ManageDevicesDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canAddDevice = widget.user.deviceIds.length < widget.user.maxDevices;
    return AlertDialog(
      title: const Text('إدارة الأجهزة'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الأجهزة المعتمدة (${widget.user.deviceIds.length}/${widget.user.maxDevices}):'),
            const SizedBox(height: 8),
            Expanded(
              child: widget.user.deviceIds.isEmpty
                  ? const Center(child: Text('لا توجد أجهزة.'))
                  : ListView(
                      shrinkWrap: true,
                      children: widget.user.deviceIds.map((id) => Row(
                        children: [
                          Expanded(child: Text(id, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => widget.cubit.removeDevice(widget.user.uid, id)),
                        ],
                      )).toList(),
                    ),
            ),
            const Divider(),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'إضافة معرف جهاز',
                enabled: canAddDevice,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ElevatedButton(
          onPressed: !canAddDevice ? null : () {
            if (_controller.text.isNotEmpty) {
              widget.cubit.addDevice(widget.user.uid, _controller.text);
              _controller.clear();
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
