import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:nizam/core/services/ClassGroupService.dart';
import 'package:nizam/models/student_model.dart';
import 'package:nizam/core/widgets/custom_loader.dart';
import 'package:nizam/features/statistics/view_model/statistics_cubit.dart';
import 'package:nizam/features/statistics/view_model/statistics_state.dart';
import 'package:nizam/features/statistics/view/widgets/charts_section.dart';
import 'package:nizam/features/statistics/view/widgets/detailed_lists_section.dart';
import 'package:nizam/features/statistics/view/widgets/main_statistics_section.dart';
import 'package:nizam/features/statistics/view/widgets/revenue_statistics_section.dart';
import 'package:nizam/features/statistics/view/widgets/upcoming_groups_section.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatisticsCubit(
        studentsBox: Hive.box<StudentModel>('students'),
        groupDetailsBox: ClassGroupService.groupDetailsBox,
      ),
      child: const StatisticsPageBody(),
    );
  }
}

class StatisticsPageBody extends StatelessWidget {
  const StatisticsPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات الطلاب'),
        centerTitle: true,
      ),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          if (state.status == StatisticsStatus.loading ||
              state.status == StatisticsStatus.initial) {
            return const CustomLoader();
          }

          if (state.status == StatisticsStatus.error) {
            return Center(
              child: Text(state.errorMessage ?? 'حدث خطأ غير متوقع'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<StatisticsCubit>().loadStatistics();
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                UpcomingGroupsSection(
                  upcomingGroups: state.upcomingGroups,
                  studentsPerGroup: state.studentsPerGroup,
                ),
                const SizedBox(height: 24),
                MainStatisticsSection(
                  totalStudents: state.totalStudents,
                  paidStudentsCount: state.paidStudentsCount,
                  unpaidStudentsCount: state.unpaidStudentsCount,
                  expiringPaymentsSoon: state.expiringPaymentsSoon,
                ),
                RevenueStatisticsSection(
                  totalCollectedRevenue: state.totalCollectedRevenue,
                  todayRevenue: state.todayRevenue,
                  last7DaysRevenue: state.last7DaysRevenue,
                  last30DaysRevenue: state.last30DaysRevenue,
                  currentYearRevenue: state.currentYearRevenue,
                ),
                ChartsSection(
                  monthlyRevenue: state.monthlyRevenue,
                  studentsPerClass: state.studentsPerClass,
                  studentsPerGroup: state.studentsPerGroup,
                ),
                DetailedListsSection(
                  studentsPerClass: state.studentsPerClass,
                  studentsPerGroup: state.studentsPerGroup,
                  revenuePerGroupDisplay: state.revenuePerGroupDisplay,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
