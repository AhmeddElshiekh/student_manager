import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nizam/features/payments/view_model/group_payments_details_cubit.dart';
import 'package:nizam/features/payments/view_model/group_payments_details_state.dart';
import 'package:nizam/models/student_model.dart';
import 'package:collection/collection.dart';

class GroupPaymentsDetailsView extends StatelessWidget {
  final String className;
  final String groupName;

  const GroupPaymentsDetailsView({super.key, required this.className, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GroupPaymentsDetailsCubit(className, groupName),
      child: _GroupPaymentsDetailsContent(groupName: groupName),
    );
  }
}

class _GroupPaymentsDetailsContent extends StatelessWidget {
  final String groupName;
  const _GroupPaymentsDetailsContent({required this.groupName});

  Future<void> _selectDate(BuildContext context) async {
    final cubit = context.read<GroupPaymentsDetailsCubit>();
    final currentState = cubit.state;
    DateTime initialDate = DateTime.now();
    bool isSelectionMode = false;

    if (currentState is GroupPaymentsDetailsLoaded) {
      initialDate = currentState.selectedDate;
      isSelectionMode = currentState.isSelectionMode;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      cubit.loadStudents(picked, keepSelectionState: isSelectionMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GroupPaymentsDetailsCubit, GroupPaymentsDetailsState>(
      builder: (context, state) {
        final bool isSelectionMode = state is GroupPaymentsDetailsLoaded && state.isSelectionMode;
        final int selectedCount = state is GroupPaymentsDetailsLoaded ? state.selectedStudentIds.length : 0;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(groupName, style: theme.textTheme.titleLarge),
                if (state is GroupPaymentsDetailsLoaded) ...[
                  Text(
                    'سجل الدفع لـ ${DateFormat('yyyy-MM-dd').format(state.selectedDate)}',
                    style: theme.textTheme.titleSmall?.copyWith(color: Colors.white70),
                  ),
                ]
              ],
            ),
            actions: [
              if (state is GroupPaymentsDetailsLoaded) ...[
                IconButton(
                  icon: Icon(isSelectionMode ? Icons.close : Icons.select_all),
                  onPressed: () => context.read<GroupPaymentsDetailsCubit>().toggleSelectionMode(),
                  tooltip: isSelectionMode ? 'إلغاء التحديد' : 'تحديد الطلاب',
                ),
              ],
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
                tooltip: 'اختر تاريخ',
              ),
            ],
          ),
          body: _buildBody(context, state),
          floatingActionButton: isSelectionMode && selectedCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () async {
                     await context.read<GroupPaymentsDetailsCubit>().payForSelectedStudents();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                            content: Text('تم تسجيل الدفع لـ $selectedCount طالب بنجاح.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                  },
                  icon: const Icon(Icons.check),
                  label: Text('دفع للمحددين ($selectedCount)'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, GroupPaymentsDetailsState state) {
    if (state is GroupPaymentsDetailsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is GroupPaymentsDetailsError) {
      return Center(child: Text(state.message));
    }
    if (state is GroupPaymentsDetailsLoaded) {
      final students = state.filteredStudents; // Use filtered students
      if (students.isEmpty && state.activeFilter == PaymentStatusFilter.all) {
        return const Center(child: Text('لا يوجد طلاب في هذه المجموعة.'));
      }

      return Column(
        children: [
          _buildFilterChips(context, state),
          Expanded(
            child: students.isEmpty
              ? const Center(child: Text('لا يوجد طلاب يطابقون هذا الفلتر.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 80.0), // Adjust padding
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _buildStudentCard(context, student, state);
                  },
                ),
          ),
        ],
      );
    }
    return const Center(child: Text('جاري تحميل التفاصيل...'));
  }
  
  Widget _buildFilterChips(BuildContext context, GroupPaymentsDetailsLoaded state) {
    // Helper to create labels like "Paid (10)"
    String getLabel(PaymentStatusFilter filter, String baseLabel) {
      final count = state.filterCounts[filter] ?? 0;
      return '$baseLabel ($count)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            _buildChip(context, getLabel(PaymentStatusFilter.all, 'الكل'), PaymentStatusFilter.all, state.activeFilter),
            _buildChip(context, getLabel(PaymentStatusFilter.paid, 'دفع'), PaymentStatusFilter.paid, state.activeFilter),
            _buildChip(context, getLabel(PaymentStatusFilter.unpaid, 'لم يدفع'), PaymentStatusFilter.unpaid, state.activeFilter),
            _buildChip(context, getLabel(PaymentStatusFilter.deferred, 'مؤجل'), PaymentStatusFilter.deferred, state.activeFilter),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, PaymentStatusFilter filter, PaymentStatusFilter activeFilter) {
    final bool isSelected = filter == activeFilter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            context.read<GroupPaymentsDetailsCubit>().applyFilter(filter);
          }
        },
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
        shape: StadiumBorder(
          side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300),
        ),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentModel student, GroupPaymentsDetailsLoaded state) {
    final selectedDate = state.selectedDate;
    final isSelectionMode = state.isSelectionMode;
    final isSelected = state.selectedStudentIds.contains(student.id);

    final paymentOnDate = student.paymentHistory.firstWhereOrNull((record) =>
        record.isPaid &&
        record.date.year == selectedDate.year &&
        record.date.month == selectedDate.month &&
        record.date.day == selectedDate.day);

    final bool hasPaidOnSelectedDate = paymentOnDate != null;

    Widget statusWidget;
    Color cardColor;
    bool isSelectable = false;

    if (hasPaidOnSelectedDate) {
      final paymentTime = DateFormat.jm('ar_SA').format(paymentOnDate.date);
      statusWidget = Text(paymentTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
      cardColor = Colors.green.shade400;
      isSelectable = false;
    } else {
      final lastRecord = student.paymentHistory.lastOrNull;
       if (lastRecord?.paymentMethod == 'مؤجل') {
        statusWidget = const Text('مؤجل', style: TextStyle(fontWeight: FontWeight.bold));
        cardColor = Colors.orange.shade300;
      } else {
        statusWidget = const Text('لم يدفع', style: TextStyle(fontWeight: FontWeight.bold));
        cardColor = Colors.red.shade200;
      }
      isSelectable = true;
    }

    return Card(
      color: cardColor,
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelectionMode && isSelected
            ? BorderSide(color: Theme.of(context).primaryColorDark, width: 3)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isSelectionMode && isSelectable
            ? () => context.read<GroupPaymentsDetailsCubit>().toggleStudentSelection(student.id)
            : null,
        child: ListTile(
          leading: isSelectionMode && isSelected
              ? const Icon(Icons.check_circle, color: Colors.white)
              : null,
          title: Text(student.name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
          trailing: statusWidget,
        ),
      ),
    );
  }
}