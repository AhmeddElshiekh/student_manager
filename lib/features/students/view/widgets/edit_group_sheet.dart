import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studentmanager/core/services/ClassGroupService.dart';
import 'package:studentmanager/core/services/app_settings_service.dart';
import 'package:studentmanager/models/group_details_model.dart';
import 'dart:math' as math;
import 'package:studentmanager/models/student_model.dart';


class Group {
  final String id;
  String name;
  double price;
  Group({required this.id, required this.name, required this.price});
}

class EditGroupSheet extends StatefulWidget {
  final String studentClass;
  final String oldGroup;

  const EditGroupSheet({
    Key? key,
    required this.studentClass,
    required this.oldGroup,
  }) : super(key: key);

  @override
  _EditGroupSheetState createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<EditGroupSheet>
    with SingleTickerProviderStateMixin {

  late TextEditingController priceController;
  late AnimationController _shakeAnimationController;
  late Animation<double> _shakeAnimation;

  final formKey = GlobalKey<FormState>();

  String? selectedDay;
  TimeOfDay? selectedTime;
  bool hasConflictError = false;

  final Map<int, String> dayNames = {
    DateTime.monday: 'الاثنين',
    DateTime.tuesday: 'الثلاثاء',
    DateTime.wednesday: 'الأربعاء',
    DateTime.thursday: 'الخميس',
    DateTime.friday: 'الجمعة',
    DateTime.saturday: 'السبت',
    DateTime.sunday: 'الأحد',
  };
  late final Map<String, int> dayIndexes =
  dayNames.map((key, value) => MapEntry(value, key));

  @override
  void initState() {
    super.initState();

    _shakeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _initializeGroupData();
  }

  void _initializeGroupData() {
    final initialEditDateTime =
    ClassGroupService.parseGroupDateTime(widget.oldGroup);
    final groupKey = '${widget.studentClass}_${widget.oldGroup}';
    final currentGroupDetails = ClassGroupService.groupDetailsBox.get(groupKey);

    if (initialEditDateTime != null) {
      selectedDay = dayNames[initialEditDateTime.weekday];
      selectedTime = TimeOfDay.fromDateTime(initialEditDateTime);
    }

    priceController = TextEditingController(
      text: (currentGroupDetails?.pricePerStudent ?? 0.0)
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'\.00$'), ''),
    );
  }

  @override
  void dispose() {
    priceController.dispose();
    _shakeAnimationController.dispose();
    super.dispose();
  }

  void _showTimePickerInModal() async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return child!;
      },
    );
    if (newTime != null) {
      setState(() {
        selectedTime = newTime;
      });
    }
  }

  void _saveChanges() async {
    if (formKey.currentState?.validate() ?? false) {
      setState(() {
        hasConflictError = false;
      });

      final int newDayIndex = dayIndexes[selectedDay]!;

      DateTime now = DateTime.now();
      DateTime newDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final int currentDayIndex = newDateTime.weekday;
      final int dayDifference = newDayIndex - currentDayIndex;
      newDateTime = newDateTime.add(Duration(days: dayDifference));

      final newGroupString =
          '$selectedDay ${DateFormat('h:mm a', 'ar').format(newDateTime)}';
      final newPrice = double.parse(priceController.text);

      final groupNameChanged = newGroupString != widget.oldGroup;
      final oldGroupKey = '${widget.studentClass}_${widget.oldGroup}';
      final newGroupKey = '${widget.studentClass}_$newGroupString';

      if (groupNameChanged &&
          ClassGroupService.groupDetailsBox.containsKey(newGroupKey)) {
        setState(() {
          hasConflictError = true;
        });
        _shakeAnimationController.forward(from: 0.0);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('اسم المجموعة موجود بالفعل'),
              content: Text(
                  'المجموعة "$newGroupString" موجودة بالفعل. يرجى اختيار وقت آخر.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('موافق'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final conflictResult = await ClassGroupService.checkGroupTimeConflict(
        newGroupString: newGroupString,
        excludeGroupKey: oldGroupKey,
      );

      if (conflictResult != null) {
        setState(() {
          hasConflictError = true;
        });
        _shakeAnimationController.forward(from: 0.0);
        if (context.mounted) {
          final int conflictHours = await AppSettingsService.getTimeConflictHours();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('تعارض في المواعيد'),
              content: Text(
                  'يوجد تعارض في الوقت مع مجموعة أخرى: ${conflictResult['conflictingGroup']}.\nيجب أن يكون الفارق بين المجموعات على نفس اليوم $conflictHours ساعة على الأقل.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('موافق'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (groupNameChanged) {
        final studentsBox = Hive.box<StudentModel>('students');
        final studentsToUpdate = studentsBox.values
            .where(
              (s) =>
          s.studentClass == widget.studentClass &&
              s.group == widget.oldGroup,
        )
            .toList();

        for (var student in studentsToUpdate) {
          student.group = newGroupString;
          await student.save();
        }

        final oldGroupDetails =
        ClassGroupService.groupDetailsBox.get(oldGroupKey);

        if (oldGroupDetails != null) {
          await ClassGroupService.groupDetailsBox.delete(oldGroupKey);
          final newGroupDetails = GroupDetailsModel(
            className: widget.studentClass,
            groupDateTimeString: newGroupString,
            pricePerStudent: newPrice,
            groupId: newGroupString,
          );
          await ClassGroupService.groupDetailsBox.put(newGroupKey, newGroupDetails);
        }
      } else {
        final updatedGroupDetails = GroupDetailsModel(
          className: widget.studentClass,
          groupDateTimeString: widget.oldGroup,
          pricePerStudent: newPrice,
          groupId: widget.oldGroup,
        );
        await ClassGroupService.groupDetailsBox.put(oldGroupKey, updatedGroupDetails);
      }

      if (context.mounted) {
        final message = groupNameChanged
            ? 'تم تعديل المجموعة بنجاح إلى "$newGroupString"'
            : 'تم تعديل سعر المجموعة بنجاح.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = selectedTime != null
        ? selectedTime!.format(context).replaceFirst('AM', 'ص').replaceFirst('PM', 'م')
        : 'اختر الوقت';

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('تعديل المجموعة في الصف "${widget.studentClass}"',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),

              AnimatedBuilder(
                animation: _shakeAnimationController,
                builder: (context, child) {
                  final double offset = _shakeAnimation.value *
                      math.sin(_shakeAnimationController.value * math.pi * 5);
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedDay,
                        decoration: InputDecoration(
                          labelText: 'يوم المجموعة',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: hasConflictError ? Colors.red : Colors.grey,
                              )),
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: hasConflictError ? Colors.red : null,
                          ),
                        ),
                        items: [
                          'السبت',
                          'الأحد',
                          'الاثنين',
                          'الثلاثاء',
                          'الأربعاء',
                          'الخميس',
                          'الجمعة'
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedDay = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء اختيار يوم المجموعة';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showTimePickerInModal,
                        child: AbsorbPointer(
                          child: TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'وقت المجموعة',
                              hintText: formattedTime,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: hasConflictError ? Colors.red : Colors.grey,
                                  )),
                              prefixIcon: Icon(
                                Icons.access_time,
                                color: hasConflictError ? Colors.red : null,
                              ),
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                            ),
                            validator: (value) {
                              if (selectedTime == null) {
                                return 'الرجاء اختيار الوقت';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Price TextFormField
              TextFormField(
                controller: priceController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'سعر الطالب في هذه المجموعة (جنيه)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال السعر';
                  }
                  if (double.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('حفظ التعديلات'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
