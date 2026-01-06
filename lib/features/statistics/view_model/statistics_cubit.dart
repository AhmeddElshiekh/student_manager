import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:studentmanager/features/students/view/students_view.dart';
import 'package:studentmanager/models/group_details_model.dart';
import 'package:studentmanager/models/student_model.dart';
import 'statistics_state.dart';
import 'dart:developer' as developer;

class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit({
    required this.studentsBox,
    required this.groupDetailsBox,
  }) : super(const StatisticsState()) {
    _studentsListenable = studentsBox.listenable();
    _groupsListenable = groupDetailsBox.listenable();

    _studentListener = () => loadStatistics();
    _groupListener = () => loadStatistics();

    _studentsListenable.addListener(_studentListener);
    _groupsListenable.addListener(_groupListener);

    loadStatistics();

    _timer =
        Timer.periodic(const Duration(minutes: 1), (_) => loadStatistics());
  }

  final Box<StudentModel> studentsBox;
  final Box<GroupDetailsModel> groupDetailsBox;

  late final ValueListenable<Box<StudentModel>> _studentsListenable;
  late final ValueListenable<Box<GroupDetailsModel>> _groupsListenable;

  late final VoidCallback _studentListener;
  late final VoidCallback _groupListener;
  Timer? _timer;

  @override
  Future<void> close() {
    _studentsListenable.removeListener(_studentListener);
    _groupsListenable.removeListener(_groupListener);
    _timer?.cancel();
    return super.close();
  }

  void loadStatistics() {
    try {
      if (state.status != StatisticsStatus.loading && !isClosed) {
        emit(state.copyWith(status: StatisticsStatus.loading));
      }

      if (isClosed) return;

      final allStudents = studentsBox.values.toList();
      final allGroupDetails = groupDetailsBox.values.toList();
      final now = DateTime.now();

      final totalStudents = allStudents.length;

      int paidStudentsCount = 0;
      int unpaidStudentsCount = 0;
      for (var student in allStudents) {
        if (student.isPaid) {
          paidStudentsCount++;
        } else {
          unpaidStudentsCount++;
        }
      }

      int expiringPaymentsSoon = 0;
      final oneDayFromNow = now.add(const Duration(days: 1));
      for (var student in allStudents) {
        final lastRecord =
            student.paymentHistory.lastWhereOrNull((r) => r.isPaid);
        if (lastRecord != null &&
            lastRecord.paymentExpiresAt != null &&
            lastRecord.paymentExpiresAt!.isAfter(now) &&
            lastRecord.paymentExpiresAt!.isBefore(oneDayFromNow)) {
          expiringPaymentsSoon++;
        }
      }

      final Map<String, int> studentsPerClass = {};
      final Map<String, int> studentsPerGroup = {};
      for (var student in allStudents) {
        studentsPerClass.update(student.studentClass, (v) => v + 1,
            ifAbsent: () => 1);
        studentsPerGroup.update(student.group, (v) => v + 1, ifAbsent: () => 1);
      }

      double totalCollectedRevenue = 0.0;
      double todayRevenue = 0.0;
      double last7DaysRevenue = 0.0;
      double last30DaysRevenue = 0.0;
      double currentYearRevenue = 0.0;
      final DateTime startOfDay = DateTime(now.year, now.month, now.day);
      final DateTime startOfLast7Days =
          startOfDay.subtract(const Duration(days: 7));
      final DateTime startOfLast30Days =
          startOfDay.subtract(const Duration(days: 30));
      final DateTime startOfCurrentYear = DateTime(now.year, 1, 1);
      final Map<int, double> monthlyRevenue = {};
      final Map<String, double> revenuePerGroupDisplay = {};

      for (var student in allStudents) {
        final groupKey = '${student.studentClass}_${student.group}';
        final groupDetails = groupDetailsBox.get(groupKey);
        final double pricePerStudent = groupDetails?.pricePerStudent ?? 0.0;

        for (var record in student.paymentHistory) {
          if (record.isPaid) {
            totalCollectedRevenue += pricePerStudent;

            if (record.date.year == now.year) {
              monthlyRevenue.update(
                  record.date.month, (value) => value + pricePerStudent,
                  ifAbsent: () => pricePerStudent);
            }

            if (record.date.isAfter(startOfDay)) {
              todayRevenue += pricePerStudent;
            }
            if (record.date.isAfter(startOfLast7Days)) {
              last7DaysRevenue += pricePerStudent;
            }
            if (record.date.isAfter(startOfLast30Days)) {
              last30DaysRevenue += pricePerStudent;
            }
            if (record.date.year == startOfCurrentYear.year) {
              currentYearRevenue += pricePerStudent;
            }

            if (student.isPaid) {
              revenuePerGroupDisplay.update(
                student.group,
                (value) => value + pricePerStudent,
                ifAbsent: () => pricePerStudent,
              );
            }
          }
        }
      }

      final List<GroupDetailsModel> upcomingGroups =
          allGroupDetails.where((group) {
        final DateTime? groupDateTime =
            _parseArabicGroupDateTime(group.groupDateTimeString, now);
        if (groupDateTime == null) return false;
        final bool isAfterPastThirtyMinutes =
            groupDateTime.isAfter(now.subtract(const Duration(minutes: 30)));
        final bool isBeforeNextSevenDays =
            groupDateTime.isBefore(now.add(const Duration(days: 7)));
        return isAfterPastThirtyMinutes && isBeforeNextSevenDays;
      }).toList();

      upcomingGroups.sort((a, b) {
        final DateTime? dateTimeA =
            _parseArabicGroupDateTime(a.groupDateTimeString, now);
        final DateTime? dateTimeB =
            _parseArabicGroupDateTime(b.groupDateTimeString, now);
        if (dateTimeA == null && dateTimeB == null) return 0;
        if (dateTimeA == null) return 1;
        if (dateTimeB == null) return -1;
        return dateTimeA.compareTo(dateTimeB);
      });

      if (!isClosed) {
        emit(state.copyWith(
          status: StatisticsStatus.success,
          totalStudents: totalStudents,
          paidStudentsCount: paidStudentsCount,
          unpaidStudentsCount: unpaidStudentsCount,
          expiringPaymentsSoon: expiringPaymentsSoon,
          studentsPerClass: studentsPerClass,
          studentsPerGroup: studentsPerGroup,
          totalCollectedRevenue: totalCollectedRevenue,
          todayRevenue: todayRevenue,
          last7DaysRevenue: last7DaysRevenue,
          last30DaysRevenue: last30DaysRevenue,
          currentYearRevenue: currentYearRevenue,
          monthlyRevenue: monthlyRevenue,
          revenuePerGroupDisplay: revenuePerGroupDisplay,
          upcomingGroups: upcomingGroups,
        ));
      }
    } catch (e, stackTrace) {
      developer.log('Error loading statistics',
          error: e, stackTrace: stackTrace);
      if (!isClosed) {
        emit(state.copyWith(
          status: StatisticsStatus.error,
          errorMessage: 'حدث خطأ أثناء حساب الإحصائيات.',
        ));
      }
    }
  }

  DateTime? _parseArabicGroupDateTime(
      String groupDateTimeString, DateTime now) {
    try {
      final Map<String, int> arabicWeekdays = {
        'الإثنين': DateTime.monday,
        'الثلاثاء': DateTime.tuesday,
        'الأربعاء': DateTime.wednesday,
        'الخميس': DateTime.thursday,
        'الجمعة': DateTime.friday,
        'السبت': DateTime.saturday,
        'الأحد': DateTime.sunday,
      };

      String stringToParse = groupDateTimeString;
      if (groupDateTimeString.contains(' - ')) {
        final parts = groupDateTimeString.split(' - ');
        if (parts.length < 2) return null;
        stringToParse = parts[1];
      }

      final weekdayArabic = stringToParse.split(' ')[0];
      final timeString =
          stringToParse.substring(stringToParse.indexOf(' ') + 1);

      final weekdayInt = arabicWeekdays[weekdayArabic];
      if (weekdayInt == null) return null;

      final timeFormat = DateFormat('h:mm a', 'ar');
      final parsedTime = timeFormat.parse(timeString);

      int dayDifference = weekdayInt - now.weekday;
      if (dayDifference < 0) dayDifference += 7;

      final DateTime groupDate = now.add(Duration(days: dayDifference));
      return DateTime(groupDate.year, groupDate.month, groupDate.day,
          parsedTime.hour, parsedTime.minute);
    } catch (e) {
      developer.log('Error parsing date for "$groupDateTimeString": $e');
      return null;
    }
  }
}
