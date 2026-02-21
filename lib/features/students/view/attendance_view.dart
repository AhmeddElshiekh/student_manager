import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:collection/collection.dart';
import 'package:nizam/core/services/app_settings_service.dart';
import 'package:nizam/models/student_model.dart';
import 'package:intl/intl.dart';

class CreditStudentsPage extends StatelessWidget {
  const CreditStudentsPage({super.key});

  Future<void> _showCreditStudentActionModal(BuildContext context, StudentModel student) async {
    final theme = Theme.of(context);
    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModalHandle(),
                Text(
                  'تغيير حالة الطالب',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildStudentInfoTile(student),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDetailChip(Icons.class_, student.studentClass, Colors.orange),
                    _buildDetailChip(Icons.group, _formatGroupDateTime(student.group), Colors.purple),
                    _buildDetailChip(Icons.watch_later, 'الحالة الحالية: مؤجل', Colors.blueGrey),
                  ],
                ),
                const SizedBox(height: 24),
                _buildModalButton(
                  context: modalContext,
                  label: 'تأكيد الدفع',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  onPressed: () => Navigator.pop(modalContext, 'paid'),
                ),
                const SizedBox(height: 8),
                _buildModalButton(
                  context: modalContext,
                  label: 'تغيير إلى غير مدفوع',
                  icon: Icons.cancel,
                  color: Colors.red,
                  onPressed: () => Navigator.pop(modalContext, 'unpaid'),
                ),
                const SizedBox(height: 8),
                _buildModalButton(
                  context: modalContext,
                  label: 'إلغاء',
                  icon: Icons.close,
                  isOutlined: true,
                  onPressed: () => Navigator.pop(modalContext, 'cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == 'paid') {
      final paymentDurationHours = await AppSettingsService.getPaymentDurationHours();
      final expiryDate = DateTime.now().add(Duration(hours: paymentDurationHours));
      final postponedRecord = student.paymentHistory.lastWhereOrNull((record) => record.paymentMethod == 'مؤجل');
      if (postponedRecord != null) {
        postponedRecord.isPaid = true;
        postponedRecord.paymentExpiresAt = expiryDate;
        postponedRecord.paymentMethod = 'تم الدفع من قائمة المؤجلين';
        await student.save();
      }
    } else if (result == 'unpaid') {
      final postponedRecord = student.paymentHistory.lastWhereOrNull((record) => record.paymentMethod == 'مؤجل');
      if (postponedRecord != null) {
        postponedRecord.isPaid = false;
        postponedRecord.paymentExpiresAt = null;
        postponedRecord.paymentMethod = 'تم تغيير الحالة إلى غير مدفوع من قائمة المؤجلين';
        await student.save();
      }
    }
  }

  Widget _buildModalHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStudentInfoTile(StudentModel student) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withAlpha(51),
        child: const Icon(Icons.person, color: Colors.blue),
      ),
      title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(student.studentNumber),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  String _formatGroupDateTime(String group) {
    try {
      final DateTime dt = DateTime.parse(group);
      return DateFormat('EEEE h:mm a', 'ar').format(dt);
    } catch (_) {
      return group;
    }
  }

  Widget _buildModalButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    Color? color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    final style = isOutlined
        ? OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: color ?? Colors.blueGrey),
    )
        : ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    final button = isOutlined
        ? OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: style,
    )
        : ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: style,
    );

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsBox = Hive.box<StudentModel>('students');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الطلاب على الأجل',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<StudentModel>>(
        valueListenable: studentsBox.listenable(),
        builder: (context, box, child) {
          final creditStudents = box.values.where((student) {
            final lastRecord = student.paymentHistory.lastOrNull;
            return lastRecord?.paymentMethod == 'مؤجل';
          }).toList();

          if (creditStudents.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد طلاب مسجلون على الأجل حاليًا.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: creditStudents.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final student = creditStudents[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  title: Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'الصف: ${student.studentClass}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'المجموعة: ${student.group}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  onTap: () {
                    _showCreditStudentActionModal(context, student);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
