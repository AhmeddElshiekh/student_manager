import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:nizam/core/services/app_settings_service.dart';
import 'package:nizam/models/payment_record_model.dart';
import 'package:nizam/models/student_model.dart';
import 'group_payments_details_state.dart';
import 'package:collection/collection.dart';

class GroupPaymentsDetailsCubit extends Cubit<GroupPaymentsDetailsState> {
  final String className;
  final String groupName;

  GroupPaymentsDetailsCubit(this.className, this.groupName) : super(GroupPaymentsDetailsInitial()) {
    loadStudents(DateTime.now());
  }

  Future<void> loadStudents(DateTime selectedDate, {bool keepSelectionState = false, PaymentStatusFilter? newFilter}) async {
    final currentState = state;
    Set<String> currentSelection = {};
    bool selectionMode = false;
    PaymentStatusFilter activeFilter = newFilter ?? (currentState is GroupPaymentsDetailsLoaded ? currentState.activeFilter : PaymentStatusFilter.all);

    if (keepSelectionState && currentState is GroupPaymentsDetailsLoaded) {
      currentSelection = currentState.selectedStudentIds;
      selectionMode = currentState.isSelectionMode;
    }

    try {
      emit(GroupPaymentsDetailsLoading());

      final studentsBox = await Hive.openBox<StudentModel>('students');
      final allStudentsInGroup = studentsBox.values
          .where((student) => student.studentClass == className && student.group == groupName)
          .toList();

      allStudentsInGroup.sort((a, b) => a.name.compareTo(b.name));

      final filteredData = _getFilteredData(allStudentsInGroup, selectedDate, activeFilter);

      emit(GroupPaymentsDetailsLoaded(
        allStudents: allStudentsInGroup,
        filteredStudents: filteredData.filteredStudents,
        selectedDate: selectedDate,
        selectedStudentIds: currentSelection,
        isSelectionMode: selectionMode,
        filterCounts: filteredData.filterCounts,
        activeFilter: activeFilter,
      ));
    } catch (e) {
      emit(GroupPaymentsDetailsError('حدث خطأ أثناء جلب الطلاب: $e'));
    }
  }
  
  void applyFilter(PaymentStatusFilter filter) {
    final currentState = state;
    if (currentState is GroupPaymentsDetailsLoaded) {
      final filteredData = _getFilteredData(currentState.allStudents, currentState.selectedDate, filter);
      emit(currentState.copyWith(
        activeFilter: filter,
        filteredStudents: filteredData.filteredStudents,
      ));
    }
  }

  _FilteredData _getFilteredData(List<StudentModel> allStudents, DateTime date, PaymentStatusFilter activeFilter) {
    int paidCount = 0;
    int unpaidCount = 0;
    int deferredCount = 0;

    for (var student in allStudents) {
      final paymentOnDate = student.paymentHistory.firstWhereOrNull((record) =>
          record.isPaid &&
          record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day);

      if (paymentOnDate != null) {
        paidCount++;
      } else {
        final lastRecord = student.paymentHistory.lastOrNull;
        if (lastRecord?.paymentMethod == 'مؤجل') {
          deferredCount++;
        } else {
          unpaidCount++;
        }
      }
    }

    final filterCounts = {
      PaymentStatusFilter.all: allStudents.length,
      PaymentStatusFilter.paid: paidCount,
      PaymentStatusFilter.unpaid: unpaidCount,
      PaymentStatusFilter.deferred: deferredCount,
    };

    List<StudentModel> filteredStudents;
    switch (activeFilter) {
      case PaymentStatusFilter.paid:
        filteredStudents = allStudents.where((s) => s.paymentHistory.any((p) => p.isPaid && p.date.year == date.year && p.date.month == date.month && p.date.day == date.day)).toList();
        break;
      case PaymentStatusFilter.unpaid:
        filteredStudents = allStudents.where((s) {
          final paidOnDate = s.paymentHistory.any((p) => p.isPaid && p.date.year == date.year && p.date.month == date.month && p.date.day == date.day);
          final isDeferred = s.paymentHistory.lastOrNull?.paymentMethod == 'مؤجل';
          return !paidOnDate && !isDeferred;
        }).toList();
        break;
      case PaymentStatusFilter.deferred:
        filteredStudents = allStudents.where((s) => s.paymentHistory.lastOrNull?.paymentMethod == 'مؤجل').toList();
        break;
      case PaymentStatusFilter.all:
      filteredStudents = allStudents;
        break;
    }

    return _FilteredData(filteredStudents: filteredStudents, filterCounts: filterCounts);
  }

  void toggleSelectionMode() {
    final currentState = state;
    if (currentState is GroupPaymentsDetailsLoaded) {
      emit(currentState.copyWith(
        isSelectionMode: !currentState.isSelectionMode,
        selectedStudentIds: {},
      ));
    }
  }

  void toggleStudentSelection(String studentId) {
    final currentState = state;
    if (currentState is GroupPaymentsDetailsLoaded) {
      final newSelectedIds = Set<String>.from(currentState.selectedStudentIds);
      if (newSelectedIds.contains(studentId)) {
        newSelectedIds.remove(studentId);
      } else {
        newSelectedIds.add(studentId);
      }
      emit(currentState.copyWith(selectedStudentIds: newSelectedIds));
    }
  }

  Future<void> payForSelectedStudents() async {
    final currentState = state;
    if (currentState is GroupPaymentsDetailsLoaded) {
      if (currentState.selectedStudentIds.isEmpty) return;

      try {
        final studentsBox = await Hive.openBox<StudentModel>('students');
        final paymentDurationHours = await AppSettingsService.getPaymentDurationHours();

        for (final studentId in currentState.selectedStudentIds) {
          final student = studentsBox.get(studentId);
          if (student != null) {
            final newPaymentHistory = List<PaymentRecord>.from(student.paymentHistory);
            final DateTime paymentExpiry = DateTime.now().add(Duration(hours: paymentDurationHours));

            newPaymentHistory.add(PaymentRecord(
              date: DateTime.now(),
              isPaid: true,
              paymentExpiresAt: paymentExpiry,
              paymentMethod: 'دفع مجمع',
            ));

            final updatedStudent = student.copyWith(paymentHistory: newPaymentHistory);
            await studentsBox.put(student.key, updatedStudent);
          }
        }
        await loadStudents(currentState.selectedDate, newFilter: currentState.activeFilter);
      } catch (e) {
        emit(GroupPaymentsDetailsError('حدث خطأ أثناء تسجيل الدفع: $e'));
      }
    }
  }
}

// Helper class to return both filtered list and counts
class _FilteredData {
  final List<StudentModel> filteredStudents;
  final Map<PaymentStatusFilter, int> filterCounts;

  _FilteredData({required this.filteredStudents, required this.filterCounts});
}
