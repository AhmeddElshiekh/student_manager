import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nizam/core/services/app_settings_service.dart';
import 'package:nizam/core/services/auto_sync_service.dart';
import 'package:nizam/core/services/firebase_backup_service.dart';
import 'package:nizam/models/group_details_model.dart';
import 'package:nizam/models/student_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:workmanager/workmanager.dart';
import '../../../core/services/ClassGroupService.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final FirebaseBackupService _firebaseBackupService = FirebaseBackupService();

  SettingsCubit() : super(SettingsState.initial()) {
    _loadSettings();
  }

  static const String _themeModeKey = 'theme_mode';
  static const String _backupHistoryKey = 'backup_history';
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';
  static const String _autoBackupIntervalKey = 'auto_backup_interval_days';

  List<List<dynamic>>? _pendingCsvFields;

  Future<void> _loadSettings() async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      final prefs = await SharedPreferences.getInstance();

      final timeConflictHours = await AppSettingsService.getTimeConflictHours();
      final paymentDurationHours = await AppSettingsService.getPaymentDurationHours();

      final themeModeIndex = prefs.getInt(_themeModeKey) ?? AppThemeMode.system.index;
      final isAutoBackupEnabled = prefs.getBool(_autoBackupEnabledKey) ?? false;
      final autoBackupIntervalDays = prefs.getInt(_autoBackupIntervalKey) ?? 1440;
      final backupHistory = prefs.getStringList(_backupHistoryKey) ?? [];
      final lastBackup = await _firebaseBackupService.getLastBackupTime();

      emit(state.copyWith(
        status: SettingsStatus.success,
        themeMode: AppThemeMode.values[themeModeIndex],
        backupHistory: backupHistory,
        isAutoBackupEnabled: isAutoBackupEnabled,
        autoBackupIntervalDays: autoBackupIntervalDays,
        timeConflictHours: timeConflictHours,
        paymentDurationHours: paymentDurationHours,
        lastFirebaseBackupTime: lastBackup,
      ));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  void setThemeMode(AppThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, themeMode.index);
    emit(state.copyWith(themeMode: themeMode));
  }

  void clearMessages() {
    emit(state.copyWith(clearMessages: true));
  }

  void setTimeConflictHours(int hours) async {
    await AppSettingsService.setTimeConflictHours(hours);
    emit(state.copyWith(timeConflictHours: hours));
  }

  void setPaymentDurationHours(int hours) async {
    await AppSettingsService.setPaymentDurationHours(hours);
    emit(state.copyWith(paymentDurationHours: hours));
  }


  Future<void> performFirebaseBackup({required bool merge}) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      await _ensureHiveBoxesAreOpen();
      await _firebaseBackupService.uploadBackup(merge: merge);
      await _loadSettings();
      emit(state.copyWith(status: SettingsStatus.success, successMessage: 'تم النسخ الاحتياطي إلى Firebase بنجاح!'));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'فشل النسخ الاحتياطي: $e'));
    }
  }
  Future<void> restoreFirebaseBackup({required bool merge}) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      await _ensureHiveBoxesAreOpen();
      await _firebaseBackupService.downloadBackup(merge: merge);
      emit(state.copyWith(
        status: SettingsStatus.success,
        successMessage: 'تم استعادة البيانات بنجاح!',
      ));
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: 'فشل استعادة البيانات: $message',
      ));
    }
  }


  void toggleAutoBackup(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enable);
    emit(state.copyWith(isAutoBackupEnabled: enable));

    const taskName = "com.nizam.backupTask";
    if (enable) {
      Workmanager().registerPeriodicTask(
        taskName,
        taskName,
        initialDelay: const Duration(minutes: 1),
        frequency: Duration(minutes: state.autoBackupIntervalDays),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } else {
      Workmanager().cancelByUniqueName(taskName);
    }
  }

  void setAutoBackupInterval(int intervalMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoBackupIntervalKey, intervalMinutes);
    emit(state.copyWith(autoBackupIntervalDays: intervalMinutes));

    if (state.isAutoBackupEnabled) {
      toggleAutoBackup(false);
      toggleAutoBackup(true);
    }
  }


  Future<void> exportDataToJson() async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      await _ensureHiveBoxesAreOpen();

      final studentsBox = Hive.box<StudentModel>('students');
      final groupsBox = Hive.box<GroupDetailsModel>('groups');
      final classesBox = Hive.box<String>('classes');

      final exportData = {
        'students': studentsBox.values.map((e) => e.toJson()).toList(),
        'groups': groupsBox.values.map((e) => e.toJson()).toList(),
        'classes': classesBox.values.toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'Nizam_Backup_$timestamp.json';

      // Convert the data to bytes.
      final String jsonString = jsonEncode(exportData);
      final Uint8List bytes = utf8.encode(jsonString);

      final String? result = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ النسخة الاحتياطية',
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        await _addBackupRecordToHistory();
        emit(state.copyWith(
          status: SettingsStatus.success,
          successMessage: 'تم حفظ النسخة الاحتياطية بنجاح!',
        ));
      } else {
        // User canceled the picker
        emit(state.copyWith(status: SettingsStatus.initial, errorMessage: 'تم إلغاء عملية الحفظ.'));
      }
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'خطأ في تصدير البيانات: $e'));
    }
  }

  Future<void> importDataFromJson({required bool overwrite}) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) {
        emit(state.copyWith(status: SettingsStatus.initial, errorMessage: 'لم يتم اختيار ملف.'));
        return;
      }

      final file = File(result.files.single.path!);
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      await _ensureHiveBoxesAreOpen();

      final classesBox = Hive.box<String>('classes');
      final groupsBox = Hive.box<GroupDetailsModel>('groups');
      final studentsBox = Hive.box<StudentModel>('students');

      if (overwrite) {
        await studentsBox.clear();
        await groupsBox.clear();
        await classesBox.clear();
      }

      final summary = await _performImport(data, studentsBox, groupsBox, classesBox);

      emit(state.copyWith(
        status: SettingsStatus.success,
        successMessage: 'تم الاستيراد بنجاح! $summary',
      ));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'خطأ في استيراد البيانات: $e'));
    }
  }

  /// Analyzes a CSV file for conflicts and updates the state with the findings.
  Future<void> importStudentsFromCsv() async {
    emit(state.copyWith(status: SettingsStatus.loading, clearMessages: true, clearConflicts: true));

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.single.path == null) {
        emit(state.copyWith(status: SettingsStatus.initial, errorMessage: 'لم يتم اختيار ملف CSV.'));
        return;
      }

      final path = result.files.single.path!;
      final input = File(path).openRead();
      final fields = await input.transform(const Utf8Decoder()).transform(const CsvToListConverter()).toList();

      if (fields.isEmpty) {
        emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'ملف CSV فارغ!'));
        return;
      }

      await _ensureHiveBoxesAreOpen();

      final studentsBox = Hive.box<StudentModel>('students');
      final List<StudentConflict> foundConflicts = [];

      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length < 6) continue;

        final studentNumber = normalizeEgyptianPhone(row[2]?.toString() ?? '');
        if (studentNumber.isEmpty) continue;

        final existingStudent = studentsBox.values.firstWhereOrNull((s) => s.studentNumber == studentNumber);

        if (existingStudent != null) {
          foundConflicts.add(StudentConflict(
            studentNumber: studentNumber,
            oldName: existingStudent.name,
            newName: row[1]?.toString().trim() ?? '',
            newClass: row[4]?.toString().trim() ?? '',
            newGroup: row[5]?.toString().trim() ?? '',
          ));
        }
      }

      if (foundConflicts.isNotEmpty) {
        _pendingCsvFields = fields;
        emit(state.copyWith(
          status: SettingsStatus.success,
          csvConflicts: foundConflicts,
        ));
      } else {
        // No conflicts, process immediately
        final summary = await _processCsvFields(fields);
        emit(state.copyWith(status: SettingsStatus.success, successMessage: 'تم استيراد CSV بنجاح! $summary'));
      }
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'خطأ أثناء استيراد CSV: $e'));
    }
  }


  Future<void> confirmCsvImport({List<String>? studentNumbersToUpdate}) async {
    if (_pendingCsvFields == null) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'لا يوجد استيراد للمتابعة.'));
      return;
    }
    
    final allConflictingNumbers = state.csvConflicts.map((c) => c.studentNumber).toSet();
    final Set<String> numbersToSkip;

    if (studentNumbersToUpdate == null) {
      // Update All: Skip none of the conflicts.
      numbersToSkip = <String>{};
    } else {
      // Skip the conflicts that were NOT selected by the user.
      numbersToSkip = allConflictingNumbers.difference(studentNumbersToUpdate.toSet());
    }

    emit(state.copyWith(status: SettingsStatus.loading, clearConflicts: true));

    try {
      final summary = await _processCsvFields(_pendingCsvFields!, numbersToSkip: numbersToSkip);
      
      _pendingCsvFields = null;

      emit(state.copyWith(status: SettingsStatus.success, successMessage: 'اكتمل الاستيراد بنجاح! $summary'));
    } catch (e) {
      _pendingCsvFields = null;
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'خطأ أثناء تأكيد الاستيراد: $e'));
    }
  }

  /// Cancels the pending CSV import and clears any conflicts.
  void cancelCsvImport() {
    _pendingCsvFields = null;
    emit(state.copyWith(status: SettingsStatus.initial, clearConflicts: true));
  }

  Future<void> addPredefinedClasses(String stage) async {
    await ClassGroupService.addStageClasses(stage);
    emit(state.copyWith(successMessage: 'تمت إضافة صفوف $stage بنجاح'));
  }

  Future<void> resetAllData() async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      await AutoSyncService.instance.resetCloudData();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_backupHistoryKey);

      emit(state.copyWith(
        status: SettingsStatus.success,
        backupHistory: [],
        successMessage: 'تمت إعادة تعيين جميع البيانات على السحابة بنجاح!',
      ));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'خطأ في إعادة تعيين البيانات: $e'));
    }
  }


  Future<void> _addBackupRecordToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final updatedHistory = List<String>.from(state.backupHistory)
      ..insert(0, 'تم التصدير يدوياً في: ${DateTime.now().toIso8601String()}');
    await prefs.setStringList(_backupHistoryKey, updatedHistory);
    emit(state.copyWith(backupHistory: updatedHistory));
  }


  Future<void> _ensureHiveBoxesAreOpen() async {
    if (!Hive.isBoxOpen('students')) await Hive.openBox<StudentModel>('students');
    if (!Hive.isBoxOpen('groups')) await Hive.openBox<GroupDetailsModel>('groups');
    if (!Hive.isBoxOpen('classes')) await Hive.openBox<String>('classes');
  }

  Future<String> _performImport(Map<String, dynamic> data, Box<StudentModel> studentsBox, Box<GroupDetailsModel> groupsBox, Box<String> classesBox) async {
    int studentsAdded = 0;
    int studentsUpdated = 0;

    final List<String> importedClasses = List<String>.from(data['classes'] ?? []);
    for (final className in importedClasses) {
      if (!classesBox.values.contains(className)) {
        await classesBox.add(className);
      }
    }

    final List<Map<String, dynamic>> importedGroupsJson = List<Map<String, dynamic>>.from(data['groups'] ?? []);
    for (final g in importedGroupsJson) {
      final group = GroupDetailsModel.fromJson(g);
      await groupsBox.put('${group.className}_${group.groupDateTimeString}', group);
    }

    final List<Map<String, dynamic>> importedStudentsJson = List<Map<String, dynamic>>.from(data['students'] ?? []);
    for (final s in importedStudentsJson) {
      final importedStudent = StudentModel.fromJson(s);
      StudentModel? existingStudent = studentsBox.values.firstWhereOrNull((student) => student.studentNumber == importedStudent.studentNumber);
      if (existingStudent != null) {
        studentsUpdated++;
      } else {
        await studentsBox.put(importedStudent.id, importedStudent);
        studentsAdded++;
      }
    }

    return 'أُضيف: $studentsAdded، حُدِّث: $studentsUpdated';
  }

  String normalizeEgyptianPhone(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length == 10) {
      return '0$digitsOnly';
    }

    return digitsOnly;
  }

  Future<String> _processCsvFields(List<List<dynamic>> fields, {Set<String> numbersToSkip = const {}}) async {
    int importedCount = 0;
    int updatedCount = 0;
    int skippedCount = 0;

    final studentsBox = Hive.box<StudentModel>('students');
    final classesBox = Hive.box<String>('classes');

    final existingClasses = classesBox.values.toSet();

    for (int i = 1; i < fields.length; i++) {
      final row = fields[i];

      if (row.length < 6) {
        skippedCount++;
        continue;
      }

      final studentNumber = normalizeEgyptianPhone(row[2]?.toString() ?? '');
      final name = row[1]?.toString().trim();
      final parentNumber  = normalizeEgyptianPhone(row[3]?.toString() ?? '');
      final studentClass = row[4]?.toString().trim();
      final group = row[5]?.toString().trim();

      if ([name, studentNumber, parentNumber, studentClass, group].any((e) => e == null || e.isEmpty)) {
        skippedCount++;
        continue;
      }

      if (numbersToSkip.contains(studentNumber)) {
        skippedCount++;
        continue;
      }

      if (!existingClasses.contains(studentClass)) {
        await classesBox.add(studentClass!);
        existingClasses.add(studentClass);
      }

      final existingStudent = studentsBox.values.firstWhereOrNull((s) => s.studentNumber == studentNumber);

      if (existingStudent != null) {
        existingStudent.name = name!;
        existingStudent.parentNumber = parentNumber!;
        existingStudent.studentClass = studentClass!;
        existingStudent.group = group!;
        existingStudent.originalGroup ??= group;
        await existingStudent.save();
        updatedCount++;
      } else {
        final student = StudentModel(
          name: name!,
          studentNumber: studentNumber,
          parentNumber: parentNumber,
          studentClass: studentClass!,
          group: group!,
          paymentHistory: [],
          originalGroup: group,
        );

        await studentsBox.put(student.id, student);
        importedCount++;
      }
    }

    return 'أُضيف: $importedCount، حُدِّث: $updatedCount، تم تخطي: $skippedCount';
  }
}
