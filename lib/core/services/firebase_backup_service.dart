import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nizam/models/group_details_model.dart';
import 'package:nizam/models/student_model.dart';

class FirebaseBackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> uploadBackup({required bool merge}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('لم يتم العثور على مستخدم مُسجَّل الدخول.');

    if (!Hive.isBoxOpen('students'))
      await Hive.openBox<StudentModel>('students');
    if (!Hive.isBoxOpen('groups'))
      await Hive.openBox<GroupDetailsModel>('groups');

    final studentsBox = Hive.box<StudentModel>('students');
    final groupsBox = Hive.box<GroupDetailsModel>('groups');

    final studentsData = studentsBox.values.map((s) => s.toJson()).toList();
    final groupsData = groupsBox.values.map((g) => g.toJson()).toList();

    final userBackupRef = _firestore.collection('backups').doc(user.uid);

    if (merge) {
      final doc = await userBackupRef.get();
      if (doc.exists && doc.data() != null) {
        final existingData = doc.data()!;
        final existingStudents = (existingData['students'] as List<dynamic>?)
                ?.map((s) => StudentModel.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [];
        final existingGroups = (existingData['groups'] as List<dynamic>?)
                ?.map((g) =>
                    GroupDetailsModel.fromJson(g as Map<String, dynamic>))
                .toList() ??
            [];

        final mergedStudents = {
          ...{for (var s in existingStudents) s.id: s},
          ...{for (var s in studentsBox.values) s.id: s}
        }.values.map((s) => s.toJson()).toList();

        final mergedGroups = {
          ...{
            for (var g in existingGroups)
              '${g.className}_${g.groupDateTimeString}': g
          },
          ...{
            for (var g in groupsBox.values)
              '${g.className}_${g.groupDateTimeString}': g
          }
        }.values.map((g) => g.toJson()).toList();

        await userBackupRef.set({
          'students': mergedStudents,
          'groups': mergedGroups,
          'lastBackupAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userBackupRef.set({
          'students': studentsData,
          'groups': groupsData,
          'lastBackupAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      await userBackupRef.set({
        'students': studentsData,
        'groups': groupsData,
        'lastBackupAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> downloadBackup({required bool merge}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('لم يتم العثور على مستخدم مُسجَّل الدخول.');

    if (!Hive.isBoxOpen('students'))
      await Hive.openBox<StudentModel>('students');
    if (!Hive.isBoxOpen('groups'))
      await Hive.openBox<GroupDetailsModel>('groups');

    final userBackupRef = _firestore.collection('backups').doc(user.uid);
    final doc = await userBackupRef.get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('لا يوجد نسخة احتياطية لهذا المستخدم.');
    }

    final data = doc.data()!;
    final studentsData = data['students'] as List<dynamic>;
    final groupsData = data['groups'] as List<dynamic>;

    final studentsBox = Hive.box<StudentModel>('students');
    final groupsBox = Hive.box<GroupDetailsModel>('groups');

    if (merge) {
      for (var studentJson in studentsData) {
        final student =
            StudentModel.fromJson(studentJson as Map<String, dynamic>);
        await studentsBox.put(student.id, student);
      }
      for (var groupJson in groupsData) {
        final group =
            GroupDetailsModel.fromJson(groupJson as Map<String, dynamic>);
        await groupsBox.put(
            '${group.className}_${group.groupDateTimeString}', group);
      }
    } else {
      await studentsBox.clear();
      await groupsBox.clear();

      for (var studentJson in studentsData) {
        final student =
            StudentModel.fromJson(studentJson as Map<String, dynamic>);
        await studentsBox.put(student.id, student);
      }

      for (var groupJson in groupsData) {
        final group =
            GroupDetailsModel.fromJson(groupJson as Map<String, dynamic>);
        await groupsBox.put(
            '${group.className}_${group.groupDateTimeString}', group);
      }
    }
  }

  Future<DateTime?> getLastBackupTime() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    if (!Hive.isBoxOpen('backups')) await Hive.openBox<String>('backups');

    final doc = await _firestore.collection('backups').doc(user.uid).get();
    if (!doc.exists ||
        doc.data() == null ||
        doc.data()!['lastBackupAt'] == null) {
      return null;
    }
    final timestamp = doc.data()!['lastBackupAt'] as Timestamp;
    return timestamp.toDate();
  }
}
