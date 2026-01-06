import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:studentmanager/core/services/app_settings_service.dart';
import 'package:studentmanager/models/student_model.dart';
import 'package:studentmanager/models/payment_record_model.dart';
import 'package:uuid/uuid.dart';
import 'package:studentmanager/core/services/ClassGroupService.dart';
import 'package:studentmanager/models/group_details_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:collection/collection.dart';


String _convertEasternArabicToWesternNumerals(String input) {
  return input
      .replaceAll('٠', '0')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9');
}

Map<String, dynamic>? _parseGroupString(String groupString) {
  final Map<String, int> dayIndexes = {
    'الاثنين': DateTime.monday,
    'الثلاثاء': DateTime.tuesday,
    'الأربعاء': DateTime.wednesday,
    'الخميس': DateTime.thursday,
    'الجمعة': DateTime.friday,
    'السبت': DateTime.saturday,
    'الأحد': DateTime.sunday,
  };
  try {
    final parts = groupString.split(' ');
    if (parts.length < 3) return null;
    final dayPart = parts[0];
    final timePart = parts[1];
    final amPmPart = parts[2];

    final dayIndex = dayIndexes[dayPart];
    if (dayIndex == null) return null;

    final westernTimePart = _convertEasternArabicToWesternNumerals(timePart);
    final timeParts = westernTimePart.split(':');
    if (timeParts.length < 2) return null;
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    if (amPmPart.toLowerCase() == 'م' || amPmPart.toLowerCase() == 'pm') {
      if (hour < 12) hour += 12;
    } else if (amPmPart.toLowerCase() == 'ص' || amPmPart.toLowerCase() == 'am') {
      if (hour == 12) hour = 0;
    }

    final dayNames = {
      DateTime.monday: 'الاثنين',
      DateTime.tuesday: 'الثلاثاء',
      DateTime.wednesday: 'الأربعاء',
      DateTime.thursday: 'الخميس',
      DateTime.friday: 'الجمعة',
      DateTime.saturday: 'السبت',
      DateTime.sunday: 'الأحد',
    };
    return {
      'day': dayNames[dayIndex],
      'hour': hour,
      'minute': minute,
    };
  } catch (e) {
    return null;
  }
}

class AddStudentView extends StatefulWidget {
  final StudentModel? studentToEdit;
  final String? initialClass;
  final String? initialGroup;

  const AddStudentView({
    super.key,
    this.studentToEdit,
    this.initialClass,
    this.initialGroup,
  });

  @override
  State<AddStudentView> createState() => _AddStudentViewState();
}

class _AddStudentViewState extends State<AddStudentView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _studentNumberController;
  late TextEditingController _parentNumberController;

  String? _selectedClass;
  String? _selectedDay;
  TimeOfDay? _selectedTime;

  String _paymentStatus = 'غير مدفوع';

  late AnimationController _shakeAnimationController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.studentToEdit?.name ?? '');
    _studentNumberController = TextEditingController(text: widget.studentToEdit?.studentNumber ?? '');
    _parentNumberController = TextEditingController(text: widget.studentToEdit?.parentNumber ?? '');

    if (widget.studentToEdit != null) {
      _selectedClass = widget.studentToEdit!.studentClass;
      final parsedGroup = _parseGroupString(widget.studentToEdit!.group);
      if (parsedGroup != null) {
        _selectedDay = parsedGroup['day'];
        _selectedTime = TimeOfDay(hour: parsedGroup['hour'], minute: parsedGroup['minute']);
      }
      final lastPaymentRecord = widget.studentToEdit!.paymentHistory.lastOrNull;
      if (widget.studentToEdit!.isPaid) {
        _paymentStatus = 'مدفوع';
      } else if (lastPaymentRecord != null && lastPaymentRecord.paymentMethod == 'مؤجل') {
        _paymentStatus = 'مؤجل';
      } else {
        _paymentStatus = 'غير مدفوع';
      }
    } else {
      _selectedClass = widget.initialClass;
      if (widget.initialGroup != null) {
        final parsedGroup = _parseGroupString(widget.initialGroup!);
        if (parsedGroup != null) {
          _selectedDay = parsedGroup['day'];
          _selectedTime = TimeOfDay(hour: parsedGroup['hour'], minute: parsedGroup['minute']);
        }
      }
      _paymentStatus = 'غير مدفوع';
    }

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentNumberController.dispose();
    _parentNumberController.dispose();
    _shakeAnimationController.dispose();
    super.dispose();
  }

  void _showTimePicker() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return child!;
      },
    );
    if (newTime != null) {
      setState(() {
        _selectedTime = newTime;
      });
    }
  }

  void _showConflictDialog(String conflictingGroup, int conflictThresholdHours) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعارض في المواعيد!'),
        content: Text(
            'المجموعة الجديدة تتعارض مع مجموعة: $conflictingGroup\n'
                'يجب أن يكون فرق الوقت بين المجموعات على الأقل $conflictThresholdHours ساعة.\n'
                'الرجاء اختيار يوم أو وقت مختلف.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate() || _selectedDay == null || _selectedTime == null) {
      _shakeAnimationController.forward(from: 0.0);
      return;
    }

    final String studentName = _nameController.text.trim();
    final String studentClass = _selectedClass!.trim();

    final formattedTime = DateFormat.jm('ar').format(
      DateTime(2024, 1, 1, _selectedTime!.hour, _selectedTime!.minute),
    );
    final finalGroupIdentifier = '$_selectedDay $formattedTime';
    final groupKey = '${studentClass}_$finalGroupIdentifier';

    final bool isEditing = widget.studentToEdit != null;
    final String currentStudentNumber = _studentNumberController.text.trim();

    final studentsBox = Hive.box<StudentModel>('students');

    final bool isNewGroup = !ClassGroupService.groupDetailsBox.containsKey(groupKey);

    if (isNewGroup) {
      final conflict = await ClassGroupService.checkGroupTimeConflict(
        newGroupString: finalGroupIdentifier,
        excludeGroupKey: isEditing ? '${widget.studentToEdit!.studentClass}_${widget.studentToEdit!.group}' : null,
      );

      if (conflict != null) {
        final String conflictingGroup = conflict['conflictingGroup'];
        final int conflictHours = await AppSettingsService.getTimeConflictHours();
        if (context.mounted) {
          _showConflictDialog(conflictingGroup, conflictHours);
        }
        _shakeAnimationController.forward(from: 0.0);
        return;
      }
    }

    StudentModel student;
    final paymentDurationHours = await AppSettingsService.getPaymentDurationHours();

    if (!isEditing) {
      final existingGroup = ClassGroupService.groupDetailsBox.get(groupKey);

      if (existingGroup == null) {
        final newGroupDetails = GroupDetailsModel(
          className: studentClass,
          groupDateTimeString: finalGroupIdentifier,
          pricePerStudent: 0.0,
          groupId: finalGroupIdentifier,
        );
        ClassGroupService.groupDetailsBox.put(groupKey, newGroupDetails);
      }

      student = StudentModel(
        id: const Uuid().v4(),
        name: studentName,
        studentNumber: currentStudentNumber,
        parentNumber: _parentNumberController.text.trim(),
        studentClass: studentClass,
        group: finalGroupIdentifier,
        paymentHistory: [],
      );

      if (_paymentStatus == 'مدفوع') {
        final DateTime paymentExpiry = DateTime.now().add(Duration(hours: paymentDurationHours));
        student.paymentHistory.add(PaymentRecord(
          date: DateTime.now(),
          isPaid: true,
          paymentExpiresAt: paymentExpiry,
          paymentMethod: 'إضافة طالب جديد (مدفوع)',
        ));
      } else if (_paymentStatus == 'مؤجل') {
        student.paymentHistory.add(PaymentRecord(
          date: DateTime.now(),
          isPaid: false,
          paymentExpiresAt: null,
          paymentMethod: 'مؤجل',
        ));
      }
      studentsBox.put(student.id, student);

    } else {
      student = widget.studentToEdit!;
      final bool classOrGroupChanged = student.studentClass != studentClass || student.group != finalGroupIdentifier;

      if (classOrGroupChanged) {
        final bool? confirmMove = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد نقل الطالب'),
            content: Text('هل أنت متأكد من نقل الطالب "${student.name}" من المجموعة الحالية إلى المجموعة الجديدة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('تأكيد النقل'),
              ),
            ],
          ),
        );

        if (confirmMove != true) {
          return;
        }

        if (student.isPaid) {
          final lastActiveRecord = student.paymentHistory.lastWhereOrNull(
                (record) => record.isPaid && record.paymentExpiresAt != null && record.paymentExpiresAt!.isAfter(DateTime.now()),
          );
          if (lastActiveRecord != null) {
            lastActiveRecord.isPaid = false;
            lastActiveRecord.paymentExpiresAt = DateTime.now();
            lastActiveRecord.cancellationReason = 'تم النقل إلى مجموعة أخرى';
          }
        }
        student.studentClass = studentClass;
        student.group = finalGroupIdentifier;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم نقل الطالب ${student.name} إلى المجموعة الجديدة بنجاح.'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      student.name = studentName;
      student.studentNumber = currentStudentNumber;
      student.parentNumber = _parentNumberController.text.trim();

      final String oldPaymentStatus = student.isPaid ? 'مدفوع' : (student.paymentHistory.lastOrNull?.paymentMethod == 'مؤجل' ? 'مؤجل' : 'غير مدفوع');

      if (_paymentStatus != oldPaymentStatus) {
        if (_paymentStatus == 'مدفوع') {
          final DateTime paymentExpiry = DateTime.now().add(Duration(hours: paymentDurationHours));
          student.paymentHistory.add(PaymentRecord(
            date: DateTime.now(),
            isPaid: true,
            paymentExpiresAt: paymentExpiry,
            paymentMethod: 'تحديث فردي (مدفوع)',
          ));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تسجيل دفع الطالب ${student.name} بنجاح.'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else if (_paymentStatus == 'مؤجل') {
          final lastActiveRecord = student.paymentHistory.lastWhereOrNull(
                (record) => record.isPaid && record.paymentExpiresAt != null && record.paymentExpiresAt!.isAfter(DateTime.now()),
          );
          if (lastActiveRecord != null) {
            lastActiveRecord.isPaid = false;
            lastActiveRecord.paymentExpiresAt = DateTime.now();
            lastActiveRecord.cancellationReason = 'تم تغيير الحالة إلى مؤجل';
          }
          student.paymentHistory.add(PaymentRecord(
            date: DateTime.now(),
            isPaid: false,
            paymentExpiresAt: null,
            paymentMethod: 'مؤجل',
          ));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تحديث حالة الطالب ${student.name} إلى "مؤجل".'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else { // غير مدفوع
          final lastActiveRecord = student.paymentHistory.lastWhereOrNull(
                (record) => record.isPaid && record.paymentExpiresAt != null && record.paymentExpiresAt!.isAfter(DateTime.now()),
          );
          if (lastActiveRecord != null) {
            lastActiveRecord.isPaid = false;
            lastActiveRecord.paymentExpiresAt = DateTime.now();
            lastActiveRecord.cancellationReason = 'تم الإلغاء قسريا';
          } else {
            student.paymentHistory.add(PaymentRecord(
              date: DateTime.now(),
              isPaid: false,
              paymentExpiresAt: null,
              paymentMethod: 'تحديث فردي (إلغاء دفع)',
            ));
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم إلغاء اشتراك الطالب ${student.name} قسريًا.'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        if (_paymentStatus == 'مدفوع' && !classOrGroupChanged) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('الطالب "${student.name}" لديه بالفعل اشتراك سارٍ.'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      await student.save();
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime = _selectedTime != null
        ? _selectedTime!.format(context)
        .replaceFirst('AM', 'ص')
        .replaceFirst('PM', 'م')
        : 'اختر الوقت';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentToEdit == null ? 'إضافة طالب جديد' : 'تعديل طالب',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedBuilder(
          animation: _shakeAnimationController,
          builder: (context, child) {
            final double offset = _shakeAnimation.value * math.sin(_shakeAnimationController.value * math.pi * 5);
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                if (widget.studentToEdit != null) ...[
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'رمز QR للطالب',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        QrImageView(
                          data: widget.studentToEdit!.id,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          gapless: true,
                          errorStateBuilder: (cxt, err) {
                            return const Center(
                              child: Text(
                                'خطأ في تحميل QR code!',
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID: ${widget.studentToEdit!.id}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الطالب',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم الطالب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _studentNumberController,
                  decoration: InputDecoration(
                    labelText: 'رقم الطالب',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال رقم الطالب';
                    }
                    if (value.length != 11) {
                      return 'رقم الطالب يجب أن يكون 11 رقمًا.';
                    }
                    if (!value.startsWith('01')) {
                      return 'رقم الطالب يجب أن يبدأ بـ "01".';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _parentNumberController,
                  decoration: InputDecoration(
                    labelText: 'رقم ولي الأمر',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال رقم ولي الأمر';
                    }
                    if (value.length != 11) {
                      return 'رقم ولي الأمر يجب أن يكون 11 رقمًا.';
                    }
                    if (!value.startsWith('01')) {
                      return 'رقم ولي الأمر يجب أن يبدأ بـ "01".';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder(
                  valueListenable: ClassGroupService.classBox.listenable(),
                  builder: (context, Box<String> box, _) {
                    List<String> availableClasses = ClassGroupService.getClasses();
                    if (_selectedClass != null && !availableClasses.contains(_selectedClass)) {
                      _selectedClass = null;
                      _selectedDay = null; // Clear day
                      _selectedTime = null; // Clear time
                    }
                    if (_selectedClass == null && widget.initialClass != null && availableClasses.contains(widget.initialClass!)) {
                      _selectedClass = widget.initialClass;
                    }

                    final bool isClassDropdownEnabled = availableClasses.isNotEmpty;

                    if (!isClassDropdownEnabled) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الصف الدراسي',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'لا توجد صفوف دراسية. الرجاء إضافة صفوف أولاً.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddClassesDialog(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('إضافة صفوف'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'الرجاء إضافة صفوف دراسية أولاً.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                          ),
                        ],
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: InputDecoration(
                        labelText: 'الصف الدراسي',
                        hintText: 'اختر الصف الدراسي',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.class_),
                      ),
                      items: availableClasses.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedClass = newValue;
                          _selectedDay = null;
                          _selectedTime = null;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء اختيار الصف الدراسي';
                        }
                        return null;
                      },
                      isExpanded: true,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDay,
                        decoration: InputDecoration(
                          labelText: 'يوم المجموعة',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        items: ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDay = newValue;
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
                        onTap: _showTimePicker,
                        child: AbsorbPointer(
                          child: TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'وقت المجموعة',
                              hintText: formattedTime,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.access_time),
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                            ),
                            validator: (value) {
                              if (_selectedTime == null) {
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
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentStatus,
                  decoration: InputDecoration(
                    labelText: 'حالة الدفع',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.credit_card),
                  ),
                  items: ['مدفوع', 'غير مدفوع', 'مؤجل'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                        style: TextStyle(
                          color: value == 'مدفوع' ? Colors.green : (value == 'غير مدفوع' ? Colors.red : Colors.orange),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _paymentStatus = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saveStudent,
                  icon: const Icon(Icons.save),
                  label: Text(widget.studentToEdit == null ? 'حفظ الطالب' : 'تحديث الطالب'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddClassesDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('إضافة صفوف دراسية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('الرجاء إضافة مجموعات الصفوف الأساسية لتتمكن من اختيار الصف الدراسي للطالب:'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await ClassGroupService.addStageClasses('ابتدائي');
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة صفوف ابتدائي بنجاح'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(dialogContext);
                  }
                },
                icon: const Icon(Icons.looks_one),
                label: const Text('إضافة صفوف ابتدائي'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await ClassGroupService.addStageClasses('إعدادي');
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة صفوف إعدادي بنجاح'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(dialogContext);
                  }
                },
                icon: const Icon(Icons.looks_two),
                label: const Text('إضافة صفوف إعدادي'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await ClassGroupService.addStageClasses('ثانوي');
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة صفوف ثانوي بنجاح'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(dialogContext);
                  }
                },
                icon: const Icon(Icons.looks_3),
                label: const Text('إضافة صفوف ثانوي'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
    setState(() {});
  }
}
