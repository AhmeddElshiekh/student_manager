import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studentmanager/features/students/view/students_view.dart';
import 'package:studentmanager/models/student_model.dart';
import 'package:studentmanager/features/students/view/add_student_view.dart';
import 'package:studentmanager/core/services/ClassGroupService.dart';
import 'package:collection/collection.dart';
import '../../../core/navigation/app_router.dart';
import 'widgets/edit_group_sheet.dart';
import 'widgets/clone_group_sheet.dart';

class GroupsListView extends StatefulWidget {
  final String studentClass;
  final String? searchQuery;

  const GroupsListView({
    super.key,
    required this.studentClass,
    this.searchQuery,
  });

  @override
  State<GroupsListView> createState() => _GroupsListViewState();
}

class _GroupsListViewState extends State<GroupsListView>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool isSearching = false;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

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
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsBox = Hive.box<StudentModel>('students');
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !isSearching,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) return;
        setState(() {
          isSearching = false;
          searchQuery = '';
          _searchController.clear();
        });
      },
      child: Scaffold(
        appBar: isSearching ? _buildSearchAppBar() : _buildDefaultAppBar(theme),
        body: ValueListenableBuilder(
          valueListenable: studentsBox.listenable(),
          builder: (context, Box<StudentModel> box, _) {
            final studentsInClass = box.values
                .where((s) => s.studentClass == widget.studentClass)
                .toList();

            final filteredStudentsInClass = searchQuery.isEmpty
                ? studentsInClass
                : studentsInClass
                .where(
                  (s) => s.group
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()),
            )
                .toList();

            final Map<String, int> groupStudentCounts =
            _getGroupStudentCounts(filteredStudentsInClass);

            if (groupStudentCounts.isEmpty) {
              return _buildEmptyState();
            }

            final sortedGroups = groupStudentCounts.keys.toList();
            sortedGroups.sort((a, b) {
              final dateA = ClassGroupService.parseGroupDateTime(a);
              final dateB = ClassGroupService.parseGroupDateTime(b);
              if (dateA != null && dateB != null) {
                return dateA.compareTo(dateB);
              }
              return a.compareTo(b);
            });

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: ListView.builder(
                key: ValueKey(searchQuery),
                padding: const EdgeInsets.all(12),
                itemCount: sortedGroups.length,
                itemBuilder: (context, index) {
                  final group = sortedGroups[index];
                  final studentCount = groupStudentCounts[group]!;
                  return _buildGroupCard(
                      context, group, studentCount, theme, isDarkMode);
                },
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: ScaleTransition(
          scale: _fabScaleAnimation,
          child: FloatingActionButton.extended(
            onPressed: () => AppRouter.pushWithScaleTransition(
              context,
              AddStudentView(
                initialClass: widget.studentClass,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
            ),
            icon: const Icon(Icons.add),
            label: const Text('إضافة طالب'),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Map<String, int> _getGroupStudentCounts(List<StudentModel> students) {
    final Map<String, int> groupCounts = {};
    for (var student in students) {
      groupCounts.update(student.group, (value) => value + 1,
          ifAbsent: () => 1);
    }
    return groupCounts;
  }

  PreferredSizeWidget _buildDefaultAppBar(ThemeData theme) {
    return AppBar(
      title: Text('مجموعات الصف: ${widget.studentClass}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
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
          hintText: 'ابحث باسم المجموعة (مثلاً: السبت 2:05 صباحًا)',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
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

  StudentModel? _getFirstStudentInGroup(String group) {
    final studentsBox = Hive.box<StudentModel>('students');
    return studentsBox.values.firstWhereOrNull(
          (s) => s.studentClass == widget.studentClass && s.group == group,
    );
  }

  Widget _buildGroupCard(BuildContext context, String group, int studentCount,
      ThemeData theme, bool isDarkMode) {
    final firstStudent = _getFirstStudentInGroup(group);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(group),
        background: _buildSwipeBackground(
            text: 'تعديل',
            icon: Icons.edit,
            alignment: Alignment.centerLeft,
            color: Colors.blue),
        secondaryBackground: Row(
          children: [
            Expanded(
              child: _buildSwipeBackground(
                text: 'نسخ المجموعة',
                icon: Icons.copy,
                alignment: Alignment.centerRight,
                color: Colors.teal,
                isRight: false,
              ),
            ),
            Expanded(
              child: _buildSwipeBackground(
                text: 'حذف',
                icon: Icons.delete,
                alignment: Alignment.centerRight,
                color: Colors.red,
                isRight: true,
              ),
            ),
          ],
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await _editGroup(context, widget.studentClass, group);
            return false;
          } else if (direction == DismissDirection.endToStart) {
            return await _showCloneOrDeleteConfirmation(
                context, widget.studentClass, group);
          }
          return false;
        },
        child: Card(
          elevation: 2,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              AppRouter.pushWithSlideTransition(
                context,
                StudentsListView(
                  studentClass: widget.studentClass,
                  group: group,
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                    theme.colorScheme.secondary.withAlpha(51),
                    child:
                    Icon(Icons.group, color: theme.colorScheme.secondary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (firstStudent != null &&
                            firstStudent.originalGroup != null)
                          Text(
                            'منسوخة من: ${firstStudent.originalGroup!}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '$studentCount طلاب',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showCloneOrDeleteConfirmation(
      BuildContext context, String studentClass, String oldGroup) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر الإجراء'),
        content: Text('هل تريد نسخ مجموعة "$oldGroup" أم حذفها؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'clone'),
            child: const Text('نسخ المجموعة'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف المجموعة'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );

    if (result == 'clone') {
      await _cloneGroup(context, studentClass, oldGroup);
      return false;
    } else if (result == 'delete') {
      return await _confirmDeleteGroup(context, studentClass, oldGroup);
    }
    return false;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'لا توجد مجموعات مطابقة للبحث في هذا الصف.'
                : 'لا توجد مجموعات في هذا الصف.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'حاول بكلمة بحث أخرى.'
                : 'أضف طلابًا لهذا الصف لإنشاء مجموعات.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              AppRouter.pushWithScaleTransition(
                context,
                AddStudentView(initialClass: widget.studentClass),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة طالب لهذا الصف'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeBackground({
    required String text,
    required IconData icon,
    required Alignment alignment,
    required Color color,
    bool isRight = false,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isRight) ...[
            Text(
              text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white),
          ] else ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteGroup(
      BuildContext context, String studentClass, String group) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد حذف المجموعة'),
        content: Text(
            'هل أنت متأكد من حذف المجموعة "$group" من الصف "${studentClass}"؟ سيتم حذف جميع الطلاب بداخلها.'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text('حذف'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final studentsBox = Hive.box<StudentModel>('students');
              final studentsToDelete = studentsBox.values.where((s) =>
              s.studentClass == studentClass && s.group == group);

              for (var student in studentsToDelete) {
                await student.delete();
              }
              final groupKey = '${studentClass}_$group';
              await ClassGroupService.groupDetailsBox.delete(groupKey);
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _cloneGroup(
      BuildContext context, String studentClass, String oldGroup) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CloneGroupSheet(
          studentClass: studentClass,
          oldGroup: oldGroup,
        );
      },
    );
  }

  Future<void> _editGroup(
      BuildContext context, String studentClass, String oldGroup) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return EditGroupSheet(
          studentClass: studentClass,
          oldGroup: oldGroup,
        );
      },
    );
  }
}
