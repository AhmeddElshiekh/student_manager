import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studentmanager/features/payments/view/group_payments_details_view.dart';
import 'package:studentmanager/features/payments/view_model/class_groups_cubit.dart';
import 'package:studentmanager/features/payments/view_model/class_groups_state.dart';

class ClassGroupsView extends StatelessWidget {
  final String className;
  const ClassGroupsView({super.key, required this.className});

  void _navigateToGroupDetails(BuildContext context, String groupName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupPaymentsDetailsView(className: className, groupName: groupName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (context) => ClassGroupsCubit(className),
      child: Scaffold(
        appBar: AppBar(
          title: Text('مجموعات $className'),
        ),
        body: BlocBuilder<ClassGroupsCubit, ClassGroupsState>(
          builder: (context, state) {
            if (state is ClassGroupsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ClassGroupsError) {
              return Center(child: Text(state.message));
            }
            if (state is ClassGroupsLoaded) {
              final groupNames = state.groupNames;

              if (groupNames.isEmpty) {
                return const Center(child: Text('لا توجد مجموعات في هذا الصف.'));
              }

              return ListView.builder(
                itemCount: groupNames.length,
                itemBuilder: (context, index) {
                  final groupName = groupNames[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ListTile(
                      title: Text(groupName, style: theme.textTheme.titleMedium),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _navigateToGroupDetails(context, groupName),
                    ),
                  );
                },
              );
            }
            return const Center(child: Text('جاري تحميل المجموعات...'));
          },
        ),
      ),
    );
  }
}
