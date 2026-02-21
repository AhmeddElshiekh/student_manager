import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nizam/core/services/firebase_backup_service.dart';
import 'package:nizam/models/group_details_model.dart';
import 'package:nizam/models/student_model.dart';


class AutoSyncService {
  final FirebaseBackupService _firebaseBackupService = FirebaseBackupService();
  Timer? _debounce;
  bool _isSyncing = false;
  bool _isDebounceActive = true;

  AutoSyncService._();

  static final AutoSyncService instance = AutoSyncService._();


  Future<void> initialize() async {
    await _ensureHiveBoxesAreOpen();

    final studentsBox = Hive.box<StudentModel>('students');
    final groupsBox = Hive.box<GroupDetailsModel>('groups');
    final classesBox = Hive.box<String>('classes');

    studentsBox.watch().listen((event) {
      _debounceSyncUp();
    });

    groupsBox.watch().listen((event) {
      _debounceSyncUp();
    });
    
    classesBox.watch().listen((event) {
      _debounceSyncUp();
    });

    await syncDown();
  }


  void _debounceSyncUp() {
    if (_isSyncing || !_isDebounceActive) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(seconds: 5), () {
      syncUp();
    });
  }

  Future<void> syncUp() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      await _firebaseBackupService.uploadBackup(merge: true);
    } catch (e) {
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncDown() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _firebaseBackupService.downloadBackup(merge: true);
    } catch (e) {
    } finally {
      _isSyncing = false;
    }
  }


  Future<void> resetCloudData() async {
    _isDebounceActive = false;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await Hive.box<StudentModel>('students').clear();
      await Hive.box<GroupDetailsModel>('groups').clear();
      await Hive.box<String>('classes').clear();


      await _firebaseBackupService.uploadBackup(merge: false);

    } catch (e) {
      rethrow;
    } finally {
      _isSyncing = false;
      _isDebounceActive = true;
    }
  }


  Future<void> _ensureHiveBoxesAreOpen() async {
    if (!Hive.isBoxOpen('students')) await Hive.openBox<StudentModel>('students');
    if (!Hive.isBoxOpen('groups')) await Hive.openBox<GroupDetailsModel>('groups');
    if (!Hive.isBoxOpen('classes')) await Hive.openBox<String>('classes');
  }
}
