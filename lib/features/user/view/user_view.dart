
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nizam/features/user/view/widgets/action_buttons_list.dart';
import 'package:nizam/features/user/view/widgets/profile_card.dart';
import 'package:nizam/features/user/view_model/profile_cubit.dart';
import 'package:nizam/features/user/view_model/profile_state.dart';

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملفي الشخصي'),
        centerTitle: true,
      ),
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          final cubit = context.read<ProfileCubit>();
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: colorScheme.error,
              ),
            );
            cubit.clearMessages();
          }
          if (state.infoMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.infoMessage!),
                backgroundColor: Colors.green,
              ),
            );
            cubit.clearMessages();
          }
        },
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.status == ProfileStatus.loading || state.status == ProfileStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.firebaseUser == null || state.status == ProfileStatus.error) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'حدث خطأ غير متوقع.',
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileCard(state: state),
                  const SizedBox(height: 24),
                  ActionButtonsList(isAdmin: state.isAdmin),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}



