
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:studentmanager/features/students/view/add_student_view.dart';
import 'package:studentmanager/models/student_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:studentmanager/models/payment_record_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:flutter/services.dart' show rootBundle;
import 'package:studentmanager/core/services/ClassGroupService.dart';
import '../../settings/view_model/settings_cubit.dart';
import '../../../core/navigation/app_router.dart';

enum PaymentStatus {
  paid,
  notPaid,
  postponed,
}

class StudentsListView extends StatefulWidget {
  final String studentClass;
  final String group;

  const StudentsListView({
    super.key,
    required this.studentClass,
    required this.group,
  });

  @override
  State<StudentsListView> createState() => _StudentsListViewState();
}

class _StudentsListViewState extends State<StudentsListView> with SingleTickerProviderStateMixin {
  int filter = 0;
  final Map<int, Color> filterColors = {
    0: Colors.blue,
    1: Colors.green,
    2: Colors.orange,
    3: Colors.red,
  };
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool isSearching = false;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  Timer? _refreshTimer;

  final GlobalKey _qrKey = GlobalKey();

  bool _isMultiSelecting = false;
  final Set<String> _selectedStudentIds = {};

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _fabScaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }



  void _toggleMultiSelection() {
    setState(() {
      _isMultiSelecting = !_isMultiSelecting;
      if (!_isMultiSelecting) {
        _selectedStudentIds.clear();
      }
    });
  }

  void _toggleStudentSelection(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  void _toggleSelectAllStudents() {
    setState(() {
      final studentsBox = Hive.box<StudentModel>('students');
      final allFilteredStudents = _applyFilter(studentsBox.values.toList());

      if (_selectedStudentIds.length == allFilteredStudents.length && allFilteredStudents.isNotEmpty) {
        _selectedStudentIds.clear();
      } else {
        _selectedStudentIds.clear();
        for (var student in allFilteredStudents) {
          _selectedStudentIds.add(student.id);
        }
      }
    });
  }

  Future<void> _performBatchPaymentUpdate(bool isPaid) async {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد طالب واحد على الأقل.')),
      );
      return;
    }

    final String statusText = isPaid ? 'مدفوع' : 'غير مدفوع';
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد تحديث حالة الدفع'),
        content: Text('هل أنت متأكد من تحديد حالة دفع ${_selectedStudentIds.length} طالب إلى "$statusText"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaid ? Colors.green : Colors.red,
            ),
            child: Text('تأكيد $statusText'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحديث حالة الدفع للطلاب المحددين...'),
            ],
          ),
        ),
      );

      final studentsBox = Hive.box<StudentModel>('students');
      int updatedCount = 0;
      List<String> alreadyPaidStudents = [];

      final paymentDurationHours = context.read<SettingsCubit>().state.paymentDurationHours;

      for (String studentId in _selectedStudentIds) {
        final student = studentsBox.values.firstWhere((s) => s.id == studentId);

        if (isPaid) {
          if (student.isPaid) {
            alreadyPaidStudents.add(student.name);
            continue;
          } else {
            final DateTime paymentExpiry = DateTime.now().add(Duration(hours: paymentDurationHours));
            final newRecord = PaymentRecord(
              date: DateTime.now(),
              isPaid: true,
              paymentExpiresAt: paymentExpiry,
              paymentMethod: 'تحديث جماعي (مدفوع)',
            );
            student.paymentHistory.add(newRecord);
            await student.save();
            updatedCount++;
          }
        } else {
          if (student.isPaid) {
            final lastActiveRecord = student.paymentHistory.lastWhereOrNull(
                  (record) => record.isPaid && record.paymentExpiresAt != null && record.paymentExpiresAt!.isAfter(DateTime.now()),
            );
            if (lastActiveRecord != null) {
              lastActiveRecord.isPaid = false;
              lastActiveRecord.paymentExpiresAt = DateTime.now();
              lastActiveRecord.cancellationReason = 'تم الإلغاء قسريا (تحديد متعدد)';
            }
            await student.save();
            updatedCount++;
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        String message = 'تم تحديث حالة دفع $updatedCount طالب إلى $statusText بنجاح.';
        if (alreadyPaidStudents.isNotEmpty) {
          message += '\nالطلاب التالية أسماؤهم لديهم بالفعل اشتراك سارٍ ولم يتم تحديثهم: ${alreadyPaidStudents.join(', ')}.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: Duration(seconds: alreadyPaidStudents.isNotEmpty ? 5 : 3),
          ),
        );
        _selectedStudentIds.clear();
        _isMultiSelecting = false;
      }
    }
  }

  double _getGroupTotalPrice() {
    final studentsBox = Hive.box<StudentModel>('students');
    final currentGroupStudentsCount = studentsBox.values.where(
            (s) => s.studentClass == widget.studentClass && s.group == widget.group).length;

    final groupKey = '${widget.studentClass}_${widget.group}';
    final groupDetails = ClassGroupService.groupDetailsBox.get(groupKey);

    if (groupDetails != null) {
      return groupDetails.pricePerStudent * currentGroupStudentsCount;
    }
    return 0.0;
  }
  Widget _buildFilterChips(BuildContext context) {
    final studentsBox = Hive.box<StudentModel>('students');

    final students = studentsBox.values.where(
          (s) => s.studentClass == widget.studentClass && s.group == widget.group,
    ).toList();

    int allCount = students.length;
    int paidCount = students.where((s) => s.isPaid).length;

    int unpaidCount = students.where((s) {
      if (s.isPaid) return false;
      if (s.hasNeverPaidBefore) return false;
      final last = s.paymentHistory.lastWhereOrNull((e) => true);
      return last != null && last.cancellationReason == null;
    }).length;

    int neverPaidCount =
        students.where((s) => s.hasNeverPaidBefore).length;

    Widget buildChip({
      required int value,
      required String label,
      required Color color,
    }) {
      final bool isSelected = filter == value;

      return ChoiceChip(
        selected: isSelected,
        selectedColor: color,
        backgroundColor: color.withAlpha(30),
        onSelected: (_) => setState(() => filter = value),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: buildChip(
              value: 0,
              label: 'الكل ($allCount)',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: buildChip(
              value: 1,
              label: 'مدفوع ($paidCount)',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: buildChip(
              value: 2,
              label: 'غير مدفوع ($unpaidCount)',
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: buildChip(
              value: 3,
              label: 'لم يدفع ($neverPaidCount)',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsBox = Hive.box<StudentModel>('students');
    final theme = Theme.of(context);

    final double groupTotalPrice = _getGroupTotalPrice();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (isSearching) {
          setState(() {
            isSearching = false;
            searchQuery = '';
            _searchController.clear();
          });
          return;
        }

        if (_isMultiSelecting) {
          _toggleMultiSelection();
          return;
        }

        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: isSearching ? _buildSearchAppBar() : _buildDefaultAppBar(theme),
        body: Column(
          children: [
            if (groupTotalPrice > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إجمالي سعر المجموعة:',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${groupTotalPrice.toStringAsFixed(0)} جنيه',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

            _buildFilterChips(context),
            const SizedBox(height: 10),

            Expanded(
              child: ValueListenableBuilder(
                valueListenable: studentsBox.listenable(),
                builder: (context, Box<StudentModel> box, _) {
                  final students = _applyFilter(box.values.toList());

                  if (students.isEmpty) return _buildEmptyState();

                  students.sort((a, b) => a.name.compareTo(b.name));

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child:  LayoutBuilder(
                      builder: (context, constraints) {
                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: students.length,
                          itemBuilder: (_, index) => _buildStudentListTile(context, students[index]),
                        );
                      },
                    )

                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: _isMultiSelecting
            ? _buildMultiSelectionFABs()
            : ScaleTransition(
          scale: _fabScaleAnimation,
          child: FloatingActionButton.extended(
            heroTag: 'addStudentFab',
            onPressed: () => AppRouter.pushWithScaleTransition(
              context,
              AddStudentView(
                initialClass: widget.studentClass,
                initialGroup: widget.group,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
            ),
            icon: const Icon(Icons.add),
            label: const Text('إضافة طالب'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectionFABs() {
    final studentsBox = Hive.box<StudentModel>('students');
    final allFilteredStudents = _applyFilter(studentsBox.values.toList());
    final bool allSelected = _selectedStudentIds.length == allFilteredStudents.length && allFilteredStudents.isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FloatingActionButton.extended(
          heroTag: 'selectAllFab',
          onPressed: _toggleSelectAllStudents,
          icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
          label: Text(allSelected ? 'إلغاء تحديد الكل' : 'تحديد الكل'),
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'batchPaidFab',
          onPressed: () => _performBatchPaymentUpdate(true),
          icon: const Icon(Icons.check_circle),
          label: const Text('تأكيد دفع المحددين'),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'batchUnpaidFab',
          onPressed: () => _performBatchPaymentUpdate(false),
          icon: const Icon(Icons.cancel),
          label: const Text('إلغاء دفع المحددين'),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ],
    );
  }

  List<StudentModel> _applyFilter(List<StudentModel> students) {
    List<StudentModel> filtered = students
        .where((s) => s.studentClass == widget.studentClass && s.group == widget.group)
        .toList();

    filtered = switch (filter) {
      1 => filtered.where((s) => s.isPaid).toList(),
      2 => filtered.where((s) {
        if (s.isPaid) return false;
        if (s.hasNeverPaidBefore) return false;

        final lastRecordInHistory = s.paymentHistory.lastWhereOrNull((record) => true);
        return lastRecordInHistory != null && lastRecordInHistory.cancellationReason == null;
      }).toList(),
      3 => filtered.where((s) {
        if (s.hasNeverPaidBefore) return true;

        if (!s.isPaid && s.paymentHistory.isNotEmpty) {
          final lastRecordInHistory = s.paymentHistory.last;
          return lastRecordInHistory.cancellationReason != null;
        }
        return false;
      }).toList(),
      _ => filtered,
    };

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) =>
      s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          s.studentNumber.contains(searchQuery))
          .toList();
    }
    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('لا يوجد طلاب في هذه المجموعة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('انقر على زر + لإضافة طالب جديد',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  String _formatGroupDateTime(String groupDateTimeString) {
    try {
      final DateTime dateTime = DateTime.parse(groupDateTimeString);
      return DateFormat('EEEE h:mm a', 'ar').format(dateTime);
    } catch (e) {
      return groupDateTimeString;
    }
  }

  PreferredSizeWidget _buildDefaultAppBar(ThemeData theme) {
    return AppBar(
      title: _isMultiSelecting
          ? Text('تم تحديد: ${_selectedStudentIds.length}', style: const TextStyle(fontWeight: FontWeight.bold))
          : FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${widget.studentClass} - ${_formatGroupDateTime(widget.group)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      centerTitle: true,
      actions: [
        if (!_isMultiSelecting)
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                Icons.search,
                key: ValueKey<bool>(isSearching),
              ),
            ),
            onPressed: () {
              setState(() {
                isSearching = true;
              });
            },
          ),
        IconButton(
          icon: Icon(_isMultiSelecting ? Icons.check_box : Icons.check_box_outline_blank),
          onPressed: _toggleMultiSelection,
          tooltip: _isMultiSelecting ? 'إلغاء التحديد المتعدد' : 'تحديد متعدد',
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            Icons.arrow_back,
            key: ValueKey<bool>(isSearching),
          ),
        ),
        onPressed: () {
          setState(() {
            isSearching = false;
            searchQuery = '';
            _searchController.clear();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'ابحث باسم الطالب أو رقمه',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() => searchQuery = value.trim());
        },
      ),
      actions: [
        if (searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                searchQuery = '';
                _searchController.clear();
              });
            },
          ),
      ],
    );
  }


  Widget _buildStudentListTile(BuildContext context, StudentModel student) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedStudentIds.contains(student.id);
    final paymentStatus = _getStudentPaymentStatus(student.paymentStatus);
    final paymentStatusColor = _getPaymentStatusColor(paymentStatus);

    return Dismissible(
      key: Key(student.key.toString()),
      background: _buildSwipeBackground(
          'الاتصال بولي الأمر',
          icon: Icons.phone,
          alignment: Alignment.centerLeft,
          color: Colors.green),
      secondaryBackground: _buildSwipeBackground(
          'حذف الطالب', icon: Icons.delete, alignment: Alignment.centerRight, color: Colors.red),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _makePhoneCall(student.parentNumber);
          return false;
        } else {
          return await _confirmDelete(context, student);
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isSelected ? theme.colorScheme.primary.withAlpha(26) : null,
        child: ListTile(
          onTap: () {
            if (_isMultiSelecting) {
              _toggleStudentSelection(student.id);
            } else {
              _showStudentDetails(context, student);
            }
          },
          onLongPress: () {
            if (!_isMultiSelecting) {
              _toggleMultiSelection();
            }
            _toggleStudentSelection(student.id);
          },
          leading: _isMultiSelecting
              ? Checkbox(
            value: isSelected,
            onChanged: (bool? value) {
              _toggleStudentSelection(student.id);
            },
          )
              : CircleAvatar(
            backgroundColor: paymentStatusColor,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(
            student.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
          subtitle: Text(
            student.studentNumber,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
          trailing: _isMultiSelecting
              ? null
              : SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: Icon(Icons.edit, color: theme.primaryColor),
              onPressed: () {
                AppRouter.pushWithScaleTransition(
                  context,
                  AddStudentView(studentToEdit: student),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                );
              },
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildSwipeBackground(
      String text, {
        required IconData icon,
        required Alignment alignment,
        required Color color,
      }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment:
        alignment == Alignment.centerLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (alignment == Alignment.centerRight)
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          if (alignment == Alignment.centerRight) const SizedBox(width: 8),
          Icon(icon, color: Colors.white),
          if (alignment == Alignment.centerLeft) const SizedBox(width: 8),
          if (alignment == Alignment.centerLeft)
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, StudentModel student) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الطالب ${student.name} بشكل نهائي؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text('حذف'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await student.delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف ${student.name} بنجاح.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    var status = await Permission.phone.status;
    if (status.isDenied) {
      status = await Permission.phone.request();
    }

    if (status.isGranted) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الاتصال بـ $phoneNumber. تأكد من صحة الرقم.')),
        );
      }
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفض إذن الاتصال بشكل دائم. الرجاء تمكين الإذن من إعدادات التطبيق.'),
          action: SnackBarAction(
            label: 'الإعدادات',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لإجراء مكالمة، يجب منح إذن الاتصال.')),
      );
    }
  }

  Future<void> _shareQrCode(StudentModel student) async {
    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_code_${student.id}.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'رمز QR للطالب: ${student.name}');


    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في مشاركة رمز QR: $e')),
        );
      }
    }
  }

  Future<void> _printQrCode(StudentModel student) async {
    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final fontData = await rootBundle.load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf');
      final arabicFont = pdfWidgets.Font.ttf(fontData);

      final pdf = pdfWidgets.Document();

      pdf.addPage(
        pdfWidgets.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pdfWidgets.Context context) {
            return pdfWidgets.Center(
              child: pdfWidgets.Column(
                mainAxisAlignment: pdfWidgets.MainAxisAlignment.center,
                children: [
                  pdfWidgets.Text(
                    'بيانات الطالب',
                    style: pdfWidgets.TextStyle(fontSize: 24, fontWeight: pdfWidgets.FontWeight.bold, font: arabicFont),
                    textDirection: pdfWidgets.TextDirection.rtl,
                  ),
                  pdfWidgets.SizedBox(height: 20),
                  pdfWidgets.Text(
                    'الاسم: ${student.name}',
                    style: pdfWidgets.TextStyle(fontSize: 18, font: arabicFont),
                    textDirection: pdfWidgets.TextDirection.rtl,
                  ),
                  pdfWidgets.Text(
                    'ID: ${student.id}',
                    style: pdfWidgets.TextStyle(fontSize: 14, font: arabicFont),
                    textDirection: pdfWidgets.TextDirection.rtl,
                  ),
                  pdfWidgets.SizedBox(height: 20),
                  pdfWidgets.Image(pdfWidgets.MemoryImage(pngBytes), width: 200, height: 200),
                  pdfWidgets.SizedBox(height: 20),
                  pdfWidgets.Text(
                    'رقم الطالب: ${student.studentNumber}',
                    style: pdfWidgets.TextStyle(fontSize: 16, font: arabicFont),
                    textDirection: pdfWidgets.TextDirection.rtl,
                  ),
                  pdfWidgets.Text(
                    'رقم ولي الأمر: ${student.parentNumber}',
                    style: pdfWidgets.TextStyle(fontSize: 16, font: arabicFont),
                    textDirection: pdfWidgets.TextDirection.rtl,
                  ),
                  pdfWidgets.Text(
                    'الصف: ${student.studentClass}',
                    style: pdfWidgets.TextStyle(fontSize: 16, font: arabicFont),
                    textDirection: pdfWidgets.TextDirection.rtl,
                  ),
                  pdfWidgets.Text(
                    'المجموعة: ${_formatGroupDateTime(student.group)}',
                    style: pdfWidgets.TextStyle(fontSize: 16, font: arabicFont),
                    textDirection: pdfWidgets.TextDirection.rtl,
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في طباعة رمز QR: $e')),
        );
      }
    }
  }

  Future<void> _showStudentDetails(BuildContext context, StudentModel student) {
    final theme = Theme.of(context);
    final currentPaymentStatus = _getStudentPaymentStatus(student.paymentStatus);
    final PaymentRecord? lastPaidRecord = student.paymentHistory.lastWhereOrNull((record) => record.isPaid);
    final DateTime? lastPaymentDate = lastPaidRecord != null ? lastPaidRecord.date : null;
    final DateTime? paymentExpiresAt = lastPaidRecord != null ? lastPaidRecord.paymentExpiresAt : null;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.4,
        maxChildSize: 0.7,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.primaryColor.withAlpha(51),
                    child: Icon(Icons.person, color: theme.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(student.name,
                        style:
                        theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Text(
                      'رمز QR للطالب',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    RepaintBoundary(
                      key: _qrKey,
                      child: QrImageView(
                        data: student.id,
                        version: QrVersions.auto,
                        size: 160.0,
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
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'ID: ${student.id}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, size: 20, color: Colors.blueGrey),
                          onPressed: () {
                            Navigator.pop(context);
                            _shareQrCode(student);
                          },
                          tooltip: 'مشاركة رمز QR',
                        ),
                        IconButton(
                          icon: const Icon(Icons.print, size: 20, color: Colors.blueAccent),
                          onPressed: () {
                            Navigator.pop(context);
                            _printQrCode(student);
                          },
                          tooltip: 'طباعة رمز QR',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDetailChip(
                      icon: Icons.call, label: student.studentNumber, color: Colors.blue),
                  _buildDetailChip(
                      icon: Icons.family_restroom, label: student.parentNumber, color: Colors.green),
                  _buildDetailChip(
                      icon: Icons.class_, label: student.studentClass, color: Colors.orange),
                  _buildDetailChip(
                      icon: Icons.group,
                      label: _formatGroupDateTime(student.group),
                      color: Colors.purple),
                  _buildDetailChip(
                    icon: _getPaymentStatusIcon(currentPaymentStatus),
                    label: currentPaymentStatus == PaymentStatus.paid ? 'مدفوع حالياً' :
                    (currentPaymentStatus == PaymentStatus.notPaid ? 'غير مدفوع حالياً' : 'مؤجل حالياً'),
                    color: _getPaymentStatusColor(currentPaymentStatus),
                  ),
                  if (lastPaymentDate != null)
                    _buildDetailChip(
                      icon: Icons.calendar_today,
                      label: 'آخر تاريخ دفع: ${DateFormat('yyyy-MM-dd').format(lastPaymentDate)}',
                      color: Colors.teal,
                    ),
                  if (paymentExpiresAt != null)
                    _buildDetailChip(
                      icon: Icons.timer,
                      label: 'ينتهي في: ${DateFormat('yyyy-MM-dd HH:mm').format(paymentExpiresAt)}',
                      color: paymentExpiresAt.isBefore(DateTime.now()) ? Colors.red : Colors.blueGrey,
                    ),
                ],
              ),
              const SizedBox(height: 24),

              ExpansionTile(
                title: Text(
                  'سجل الدفع',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                initiallyExpanded: false,
                children: [
                  if (student.paymentHistory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('لا يوجد سجل دفع لهذا الطالب.'),
                    ),
                  ...student.paymentHistory.reversed.map((record) {
                    final bool isExpired = record.isPaid && record.paymentExpiresAt != null && record.paymentExpiresAt!.isBefore(DateTime.now());
                    final String expiryStatusText = isExpired ? ' (منتهي تلقائيًا)' : '';
                    final String cancellationText = record.cancellationReason != null ? ' (${record.cancellationReason})' : '';

                    IconData recordIcon;
                    Color recordColor;
                    String recordStatusText;

                    if (record.isPaid && !isExpired && record.cancellationReason == null) {
                      recordIcon = Icons.check_circle_outline;
                      recordColor = Colors.green;
                      recordStatusText = 'دفعة مسجلة';
                    } else if (record.cancellationReason != null) {
                      recordIcon = Icons.cancel_outlined;
                      recordColor = Colors.red;
                      recordStatusText = 'دفعة ملغاة قسريًا';
                    } else {
                      recordIcon = Icons.history_toggle_off;
                      recordColor = Colors.orange;
                      recordStatusText = 'دفعة منتهية';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(recordIcon, color: recordColor, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recordStatusText,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: recordColor),
                                  ),
                                  Text(
                                    'تاريخ التسجيل: ${DateFormat('yyyy-MM-dd hh:mm a', 'ar').format(record.date)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'الطريقة: ${record.paymentMethod}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                                  ),
                                  if (record.paymentExpiresAt != null)
                                    Text(
                                      'تاريخ الانتهاء: ${DateFormat('yyyy-MM-dd hh:mm a', 'ar').format(record.paymentExpiresAt!)}$expiryStatusText$cancellationText',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isExpired || record.cancellationReason != null ? Colors.red : Colors.blueGrey,
                                        fontWeight: isExpired || record.cancellationReason != null ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    AppRouter.pushWithScaleTransition(
                      context,
                      AddStudentView(studentToEdit: student),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('تعديل بيانات الطالب'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _makePhoneCall(student.parentNumber);
                  },
                  icon: const Icon(Icons.family_restroom, color: Colors.green),
                  label: Text('الاتصال بولي الأمر: ${student.parentNumber}',
                      style: const TextStyle(color: Colors.green)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _makePhoneCall(student.studentNumber);
                  },
                  icon: const Icon(Icons.call, color: Colors.blue),
                  label: Text('الاتصال بالطالب: ${student.studentNumber}',
                      style: const TextStyle(color: Colors.blue)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      backgroundColor: color.withAlpha(26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withAlpha(51)),
      ),
    );
  }


  PaymentStatus _getStudentPaymentStatus(String status) {
    if (status == 'paid') {
      return PaymentStatus.paid;
    } else if (status == 'notPaid') {
      return PaymentStatus.notPaid;
    } else if (status == 'postponed') {
      return PaymentStatus.postponed;
    }
    return PaymentStatus.notPaid;
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.notPaid:
        return Colors.red;
      case PaymentStatus.postponed:
        return Colors.orange;
    }
  }

  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.done;
      case PaymentStatus.notPaid:
        return Icons.close;
      case PaymentStatus.postponed:
        return Icons.access_time;
    }
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? lastWhereOrNull(bool Function(T element) test) {
    T? result;
    for (final element in this) {
      if (test(element)) {
        result = element;
      }
    }
    return result;
  }
}
