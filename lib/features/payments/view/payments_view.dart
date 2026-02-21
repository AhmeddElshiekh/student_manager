import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nizam/features/payments/view/class_groups_view.dart';
import 'package:nizam/features/payments/view_model/payments_cubit.dart';
import 'package:nizam/features/payments/view_model/payments_state.dart';
import 'package:nizam/features/students/view/attendance_view.dart';
import 'package:nizam/core/navigation/app_router.dart';

class PaymentsView extends StatelessWidget {
  const PaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentsCubit(),
      child: const _PaymentsViewContent(),
    );
  }
}

class _PaymentsViewContent extends StatelessWidget {
  const _PaymentsViewContent();

  void _navigateToClassGroups(BuildContext context, String className) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassGroupsView(className: className),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدفع والصفوف الدراسية'),
      ),
      body: BlocBuilder<PaymentsCubit, PaymentsState>(
        builder: (context, state) {
          if (state is PaymentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PaymentsError) {
            return Center(child: Text(state.message));
          }
          if (state is PaymentsLoaded) {
            final classNames = state.classNames;

            return ListView(
              children: [
                Card(
                  color: Colors.orange.shade800,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                    title: const Text('الطلاب المؤجلون', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onTap: () => AppRouter.push(context, const CreditStudentsPage()),
                  ),
                ),
                const Divider(),
                if (classNames.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('لا توجد صفوف دراسية لعرضها.'),
                  ))
                else
                  ...classNames.map((className) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        title: Text(className, style: theme.textTheme.titleMedium),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _navigateToClassGroups(context, className),
                      ),
                    );
                  }).toList(),
              ],
            );
          }

          return const Center(child: Text('جاري تحميل الصفوف...'));
        },
      ),
    );
  }
}
