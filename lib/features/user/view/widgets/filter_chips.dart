import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nizam/features/user/view_model/admin_cubit.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AdminCubit>();
    final currentFilter = cubit.state.filter;

    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: [
        FilterChip(
          label: const Text('الكل'),
          selected: currentFilter == 'all',
          onSelected: (_) => cubit.changeFilter('all'),
        ),
        FilterChip(
          label: const Text('المفعلون'),
          selected: currentFilter == 'approved',
          onSelected: (_) => cubit.changeFilter('approved'),
          selectedColor: Colors.green.withAlpha(51),
        ),
        FilterChip(
          label: const Text('قيد الانتظار'),
          selected: currentFilter == 'pending',
          onSelected: (_) => cubit.changeFilter('pending'),
          selectedColor: Colors.orange.withAlpha(51),
        ),
      ],
    );
  }
}
