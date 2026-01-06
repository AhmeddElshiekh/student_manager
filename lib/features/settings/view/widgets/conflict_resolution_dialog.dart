import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../view_model/settings_cubit.dart';
import '../../view_model/settings_state.dart';

class ConflictResolutionDialog extends StatefulWidget {
  final List<StudentConflict> conflicts;

  const ConflictResolutionDialog({super.key, required this.conflicts});

  @override
  State<ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  // Using a Set for efficient add/remove operations.
  late Set<String> _selectedStudentNumbers;

  @override
  void initState() {
    super.initState();
    // By default, all conflicts are selected for update.
    _selectedStudentNumbers = widget.conflicts.map((c) => c.studentNumber).toSet();
  }

  void _toggleSelection(String studentNumber) {
    setState(() {
      if (_selectedStudentNumbers.contains(studentNumber)) {
        _selectedStudentNumbers.remove(studentNumber);
      } else {
        _selectedStudentNumbers.add(studentNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('حل التعارضات (${widget.conflicts.length})'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تم العثور على طلاب بنفس رقم الهاتف. حدد الطلاب الذين تريد تحديث بياناتهم:',
            ),
            const SizedBox(height: 16),
            // Use an Expanded widget to make the list scrollable within the dialog.
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.conflicts.length,
                itemBuilder: (context, index) {
                  final conflict = widget.conflicts[index];
                  final isSelected = _selectedStudentNumbers.contains(conflict.studentNumber);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? value) {
                      _toggleSelection(conflict.studentNumber);
                    },
                    title: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'الاسم: ${conflict.oldName}'),
                          const TextSpan(text: ' ⇦ ', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          TextSpan(
                            text: conflict.newName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    subtitle: Text('صف: ${conflict.newClass} | مجموعة: ${conflict.newGroup}'),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('إلغاء'),
          onPressed: () {
            context.read<SettingsCubit>().cancelCsvImport();
            Navigator.of(context).pop();
          },
        ),
        // This button allows importing only the non-conflicting students.
        TextButton(
          child: const Text('تجاهل الكل'),
          onPressed: () {
            // Pass an empty list to indicate no conflicts should be updated.
            context.read<SettingsCubit>().confirmCsvImport(studentNumbersToUpdate: []);
            Navigator.of(context).pop();
          },
        ),
        FilledButton(
          child: Text('تحديث المحددين (${_selectedStudentNumbers.length})'),
          onPressed: () {
            context.read<SettingsCubit>().confirmCsvImport(studentNumbersToUpdate: _selectedStudentNumbers.toList());
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
