
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nizam/core/services/app_settings_service.dart';
import 'package:nizam/models/student_model.dart';
import 'package:nizam/features/students/view/groups_list_view.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/ClassGroupService.dart';
import 'add_student_view.dart';

class ClassesListView extends StatefulWidget {
  const ClassesListView({super.key});

  @override
  State<ClassesListView> createState() => _ClassesListViewState();
}

class _ClassesListViewState extends State<ClassesListView> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool isSearching = false;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Future<List<String>> _conflictsFuture;

  @override
  void initState() {
    super.initState();
    _conflictsFuture = _findAllConflicts();

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

  void _refreshConflicts() {
    setState(() {
      _conflictsFuture = _findAllConflicts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentsBox = Hive.box<StudentModel>('students');
    final theme = Theme.of(context);

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
        body: Column(
          children: [
            FutureBuilder<List<String>>(
              future: _conflictsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('خطأ في تحميل التعارضات: ${snapshot.error}'),
                  );
                }
                final conflicts = snapshot.data ?? [];
                if (conflicts.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      color: Colors.red[100],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber, color: Colors.red),
                        title: Text('${conflicts.length} تعارض في مواعيد المجموعات!',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red),
                        onTap: () => _showConflictsDialog(context, conflicts),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: studentsBox.listenable(),
                builder: (context, Box<StudentModel> box, _) {
                  final allStudents = box.values.toList();

                  // New search logic: filter students first based on class name or student name
                  final filteredStudents = allStudents.where((student) {
                    final lowerCaseQuery = searchQuery.toLowerCase();
                    final studentNameMatch = student.name.toLowerCase().contains(lowerCaseQuery);
                    final studentClassMatch = student.studentClass.toLowerCase().contains(lowerCaseQuery);

                    return studentNameMatch || studentClassMatch;
                  }).toList();

                  // Rebuild class groups and counts from the filtered list of students
                  final Map<String, Set<String>> actualClassGroups = {};
                  final Map<String, int> actualClassStudentCounts = {};

                  for (var student in filteredStudents) {
                    actualClassGroups.putIfAbsent(student.studentClass, () => {});
                    actualClassGroups[student.studentClass]!.add(student.group);
                    actualClassStudentCounts.update(
                      student.studentClass,
                          (value) => value + 1,
                      ifAbsent: () => 1,
                    );
                  }

                  // Get the list of classes to display from the filtered groups
                  List<String> displayClasses = actualClassGroups.keys.toList();
                  displayClasses.sort((a, b) => a.compareTo(b));

                  // Now, decide which list to show based on the search query
                  if (searchQuery.isNotEmpty) {
                    // If there's a search query, show student cards directly
                    if (filteredStudents.isEmpty) {
                      return _buildEmptyStateForSearch();
                    } else {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: ListView.builder(
                          key: ValueKey(searchQuery),
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            return _buildStudentCard(context, student);
                          },
                        ),
                      );
                    }
                  } else {
                    // If there's no search query, show the class cards
                    if (displayClasses.isEmpty) {
                      return _buildEmptyState();
                    }
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: ListView.builder(
                        key: ValueKey(searchQuery),
                        padding: const EdgeInsets.all(12),
                        itemCount: displayClasses.length,
                        itemBuilder: (context, index) {
                          final studentClass = displayClasses[index];
                          final groupCount = actualClassGroups[studentClass]?.length ?? 0;
                          final studentCount = actualClassStudentCounts[studentClass] ?? 0;
                          return _buildClassCard(context, studentClass, groupCount, studentCount);
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: ScaleTransition(
          scale: _fabScaleAnimation,
          child: FloatingActionButton.extended(
            heroTag: 'addStudentFab',
            onPressed: () async {
              // Push the AddStudentView and await the result (pop)
              await AppRouter.pushWithScaleTransition(
                context,
                const AddStudentView(),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
              );
              // Refresh conflicts after returning from adding/editing a student
              _refreshConflicts();
            },
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة طالب'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Future<List<String>> _findAllConflicts() async {
    final allGroups = ClassGroupService.groupDetailsBox.values.toList();
    final List<String> conflicts = [];
    final int conflictHours = await AppSettingsService.getTimeConflictHours();
    final conflictThresholdInMinutes = conflictHours * 60;

    for (int i = 0; i < allGroups.length; i++) {
      final groupA = allGroups[i];
      final groupADateTime = ClassGroupService.parseGroupDateTime(groupA.groupDateTimeString);
      if (groupADateTime == null) continue;

      for (int j = i + 1; j < allGroups.length; j++) {
        final groupB = allGroups[j];
        final groupBDateTime = ClassGroupService.parseGroupDateTime(groupB.groupDateTimeString);
        if (groupBDateTime == null) continue;

        if (groupA.groupId == groupB.groupId) {
          continue;
        }

        if (groupADateTime.weekday == groupBDateTime.weekday) {
          final differenceInMinutes = groupADateTime.difference(groupBDateTime).inMinutes.abs();

          if (differenceInMinutes < conflictThresholdInMinutes) {
            conflicts.add("⚠ مجموعة ${groupA.className} في ${groupA.groupDateTimeString} تتعارض مع مجموعة ${groupB.className} في ${groupB.groupDateTimeString}.");
          }
        }
      }
    }
    return conflicts.toSet().toList();
  }

  void _showConflictsDialog(BuildContext context, List<String> conflicts) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعارضات المجموعات'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: conflicts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(conflicts[index], style: const TextStyle(color: Colors.red)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildDefaultAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('قائمة الصفوف',
          style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
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
          hintText: 'ابحث باسم الصف أو الطالب',
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

  Widget _buildClassCard(BuildContext context, String studentClass, int groupCount, int studentCount) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (groupCount > 0) {
            await AppRouter.pushWithSlideTransition(
              context,
              GroupsListView(studentClass: studentClass),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
            );
            _refreshConflicts();
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('لا توجد مجموعات في صف "$studentClass"'),
                content: const Text('هذا الصف لا يحتوي على أي طلاب حاليًا. هل ترغب في إضافة أول طالب لهذا الصف؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await AppRouter.pushWithScaleTransition(
                        context,
                        AddStudentView(initialClass: studentClass),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                      );
                      _refreshConflicts();
                    },
                    child: const Text('إضافة طالب'),
                  ),
                ],
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.primaryColor.withAlpha(51),
                child: Icon(Icons.class_, color: theme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentClass,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$groupCount مجموعة  •  $studentCount طالب',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'لا توجد صفوف بعد',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة أول طالب ليظهر صفه هنا.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateForSearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'لا توجد نتائج',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'جرّب البحث بكلمة مختلفة.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudentCard(BuildContext context, StudentModel student) {
  final theme = Theme.of(context);
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 1,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.primaryColor.withAlpha(51),
        child: Icon(Icons.person, color: theme.primaryColor),
      ),
      title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${student.studentClass} - ${student.group}'),
      onTap: () {
        // You can add navigation to student details view here if you want
      },
    ),
  );
}

}
