import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:nizam/models/student_model.dart';
import 'payments_state.dart';

class PaymentsCubit extends Cubit<PaymentsState> {
  PaymentsCubit() : super(PaymentsInitial()) {
    loadClasses();
  }

  Future<void> loadClasses() async {
    try {
      emit(PaymentsLoading());

      final studentsBox = await Hive.openBox<StudentModel>('students');
      final allStudents = studentsBox.values.toList();

      final classNames = allStudents.map((student) => student.studentClass).toSet().toList();

      classNames.sort();

      emit(PaymentsLoaded(classNames));
    } catch (e) {
      emit(PaymentsError('حدث خطأ أثناء جلب الصفوف: $e'));
    }
  }
}
