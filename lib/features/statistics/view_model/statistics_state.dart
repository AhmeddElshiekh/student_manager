import 'package:equatable/equatable.dart';
import 'package:nizam/models/group_details_model.dart';

enum StatisticsStatus { initial, loading, success, error }

class StatisticsState extends Equatable {
  const StatisticsState({
    this.status = StatisticsStatus.initial,
    this.totalStudents = 0,
    this.paidStudentsCount = 0,
    this.unpaidStudentsCount = 0,
    this.expiringPaymentsSoon = 0,
    this.totalCollectedRevenue = 0.0,
    this.todayRevenue = 0.0,
    this.last7DaysRevenue = 0.0,
    this.last30DaysRevenue = 0.0,
    this.currentYearRevenue = 0.0,
    this.studentsPerClass = const {},
    this.studentsPerGroup = const {},
    this.revenuePerGroupDisplay = const {},
    this.monthlyRevenue = const {},
    this.upcomingGroups = const [],
    this.errorMessage,
  });

  final StatisticsStatus status;
  final int totalStudents;
  final int paidStudentsCount;
  final int unpaidStudentsCount;
  final int expiringPaymentsSoon;
  final double totalCollectedRevenue;
  final double todayRevenue;
  final double last7DaysRevenue;
  final double last30DaysRevenue;
  final double currentYearRevenue;
  final Map<String, int> studentsPerClass;
  final Map<String, int> studentsPerGroup;
  final Map<String, double> revenuePerGroupDisplay;
  final Map<int, double> monthlyRevenue;
  final List<GroupDetailsModel> upcomingGroups;
  final String? errorMessage;

  StatisticsState copyWith({
    StatisticsStatus? status,
    int? totalStudents,
    int? paidStudentsCount,
    int? unpaidStudentsCount,
    int? expiringPaymentsSoon,
    double? totalCollectedRevenue,
    double? todayRevenue,
    double? last7DaysRevenue,
    double? last30DaysRevenue,
    double? currentYearRevenue,
    Map<String, int>? studentsPerClass,
    Map<String, int>? studentsPerGroup,
    Map<String, double>? revenuePerGroupDisplay,
    Map<int, double>? monthlyRevenue,
    List<GroupDetailsModel>? upcomingGroups,
    String? errorMessage,
  }) {
    return StatisticsState(
      status: status ?? this.status,
      totalStudents: totalStudents ?? this.totalStudents,
      paidStudentsCount: paidStudentsCount ?? this.paidStudentsCount,
      unpaidStudentsCount: unpaidStudentsCount ?? this.unpaidStudentsCount,
      expiringPaymentsSoon: expiringPaymentsSoon ?? this.expiringPaymentsSoon,
      totalCollectedRevenue: totalCollectedRevenue ?? this.totalCollectedRevenue,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      last7DaysRevenue: last7DaysRevenue ?? this.last7DaysRevenue,
      last30DaysRevenue: last30DaysRevenue ?? this.last30DaysRevenue,
      currentYearRevenue: currentYearRevenue ?? this.currentYearRevenue,
      studentsPerClass: studentsPerClass ?? this.studentsPerClass,
      studentsPerGroup: studentsPerGroup ?? this.studentsPerGroup,
      revenuePerGroupDisplay: revenuePerGroupDisplay ?? this.revenuePerGroupDisplay,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      upcomingGroups: upcomingGroups ?? this.upcomingGroups,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    totalStudents,
    paidStudentsCount,
    unpaidStudentsCount,
    expiringPaymentsSoon,
    totalCollectedRevenue,
    todayRevenue,
    last7DaysRevenue,
    last30DaysRevenue,
    currentYearRevenue,
    studentsPerClass,
    studentsPerGroup,
    revenuePerGroupDisplay,
    monthlyRevenue,
    upcomingGroups,
    errorMessage,
  ];
}