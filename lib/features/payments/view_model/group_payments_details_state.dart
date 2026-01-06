import 'package:studentmanager/models/student_model.dart';

// Enum for payment status filters
enum PaymentStatusFilter {
  all,
  paid,
  unpaid,
  deferred,
}

abstract class GroupPaymentsDetailsState {}

class GroupPaymentsDetailsInitial extends GroupPaymentsDetailsState {}

class GroupPaymentsDetailsLoading extends GroupPaymentsDetailsState {}

class GroupPaymentsDetailsLoaded extends GroupPaymentsDetailsState {
  final List<StudentModel> allStudents; // All students for the group
  final List<StudentModel> filteredStudents; // Students to be displayed after filtering
  final DateTime selectedDate;
  final bool isSelectionMode;
  final Set<String> selectedStudentIds;
  final PaymentStatusFilter activeFilter;
  final Map<PaymentStatusFilter, int> filterCounts; // e.g., {all: 20, paid: 10, ...}

  GroupPaymentsDetailsLoaded({
    required this.allStudents,
    required this.filteredStudents,
    required this.selectedDate,
    required this.filterCounts,
    this.isSelectionMode = false,
    this.selectedStudentIds = const {},
    this.activeFilter = PaymentStatusFilter.all,
  });

  GroupPaymentsDetailsLoaded copyWith({
    List<StudentModel>? allStudents,
    List<StudentModel>? filteredStudents,
    DateTime? selectedDate,
    bool? isSelectionMode,
    Set<String>? selectedStudentIds,
    PaymentStatusFilter? activeFilter,
    Map<PaymentStatusFilter, int>? filterCounts,
  }) {
    return GroupPaymentsDetailsLoaded(
      allStudents: allStudents ?? this.allStudents,
      filteredStudents: filteredStudents ?? this.filteredStudents,
      selectedDate: selectedDate ?? this.selectedDate,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedStudentIds: selectedStudentIds ?? this.selectedStudentIds,
      activeFilter: activeFilter ?? this.activeFilter,
      filterCounts: filterCounts ?? this.filterCounts,
    );
  }
}

class GroupPaymentsDetailsError extends GroupPaymentsDetailsState {
  final String message;
  GroupPaymentsDetailsError(this.message);
}
