import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studentmanager/features/user/view/widgets/filter_chips.dart';
import 'package:studentmanager/features/user/view/widgets/user_card.dart';
import 'package:studentmanager/features/user/view_model/admin_cubit.dart';
import 'package:studentmanager/features/user/view_model/admin_state.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminCubit(),
      child: const AdminView(),
    );
  }
}

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('لوحة تحكم المدير'),
        backgroundColor: colorScheme.surface,
        elevation: 1,
        centerTitle: true,
      ),
      body: BlocListener<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state.status == AdminStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: colorScheme.error,
                ),
              );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const FilterChips(),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<AdminCubit, AdminState>(
                  builder: (context, state) {
                    if (state.status == AdminStatus.loading || state.status == AdminStatus.initial) {
                      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                    }

                    final filteredUsers = state.users.where((user) {
                      if (state.filter == 'approved') return user.isApproved;
                      if (state.filter == 'pending') return !user.isApproved;
                      return true;
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return const Center(child: Text('لا يوجد مستخدمون'));
                    }

                    return ListView.builder(
                      itemCount: filteredUsers.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        return UserCard(user: filteredUsers[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
