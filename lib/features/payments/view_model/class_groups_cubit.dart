import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:studentmanager/models/student_model.dart';
import 'class_groups_state.dart';

class ClassGroupsCubit extends Cubit<ClassGroupsState> {
  final String className;

  ClassGroupsCubit(this.className) : super(ClassGroupsInitial()) {
    loadGroups();
  }

  Future<void> loadGroups() async {
    try {
      emit(ClassGroupsLoading());

      final studentsBox = await Hive.openBox<StudentModel>('students');
      final allStudents = studentsBox.values.toList();

      final groupNames = allStudents
          .where((student) => student.studentClass == className)
          .map((student) => student.group)
          .toSet()
          .toList();

      groupNames.sort();

      emit(ClassGroupsLoaded(groupNames));
    } catch (e) {
      emit(ClassGroupsError('حدث خطأ أثناء جلب المجموعات: $e'));
    }
  }
}
