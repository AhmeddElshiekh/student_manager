
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum SettingsStatus { initial, loading, success, error }

enum AppThemeMode { light, dark, system }

// A new class to hold the details of a single student conflict.
class StudentConflict extends Equatable {
  final String studentNumber;
  final String oldName;
  final String newName;
  final String newClass;
  final String newGroup;

  const StudentConflict({
    required this.studentNumber,
    required this.oldName,
    required this.newName,
    required this.newClass,
    required this.newGroup,
  });

  @override
  List<Object?> get props => [studentNumber, oldName, newName, newClass, newGroup];
}


@immutable
class SettingsState extends Equatable {
  final SettingsStatus status;
  final AppThemeMode themeMode;
  final List<String> backupHistory;
  final bool isAutoBackupEnabled;
  final int autoBackupIntervalDays;
  final int timeConflictHours;
  final int paymentDurationHours;
  final DateTime? lastFirebaseBackupTime;
  final String? successMessage;
  final String? errorMessage;
  // A list to hold detected conflicts from a CSV import.
  final List<StudentConflict> csvConflicts;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.themeMode = AppThemeMode.system,
    this.backupHistory = const [],
    this.isAutoBackupEnabled = false,
    this.autoBackupIntervalDays = 1440,
    this.timeConflictHours = 2,
    this.paymentDurationHours = 24,
    this.lastFirebaseBackupTime,
    this.successMessage,
    this.errorMessage,
    this.csvConflicts = const [],
  });

  factory SettingsState.initial() {
    return const SettingsState();
  }

  SettingsState copyWith({
    SettingsStatus? status,
    AppThemeMode? themeMode,
    List<String>? backupHistory,
    bool? isAutoBackupEnabled,
    int? autoBackupIntervalDays,
    int? timeConflictHours,
    int? paymentDurationHours,
    DateTime? lastFirebaseBackupTime,
    String? successMessage,
    String? errorMessage,
    List<StudentConflict>? csvConflicts,
    bool clearMessages = false,
    bool clearConflicts = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      themeMode: themeMode ?? this.themeMode,
      backupHistory: backupHistory ?? this.backupHistory,
      isAutoBackupEnabled: isAutoBackupEnabled ?? this.isAutoBackupEnabled,
      autoBackupIntervalDays: autoBackupIntervalDays ?? this.autoBackupIntervalDays,
      timeConflictHours: timeConflictHours ?? this.timeConflictHours,
      paymentDurationHours: paymentDurationHours ?? this.paymentDurationHours,
      lastFirebaseBackupTime: lastFirebaseBackupTime ?? this.lastFirebaseBackupTime,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      csvConflicts: clearConflicts ? [] : csvConflicts ?? this.csvConflicts,
    );
  }

  @override
  List<Object?> get props => [
    status,
    themeMode,
    backupHistory,
    isAutoBackupEnabled,
    autoBackupIntervalDays,
    timeConflictHours,
    paymentDurationHours,
    lastFirebaseBackupTime,
    successMessage,
    errorMessage,
    csvConflicts,
  ];
}
