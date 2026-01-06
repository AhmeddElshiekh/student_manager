import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  AdminCubit() : super(const AdminState()) {
    _listenToUsers();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _userSubscription;

  void _listenToUsers() {
    emit(state.copyWith(status: AdminStatus.loading));
    _userSubscription = _firestore.collection('users').snapshots().listen(
          (snapshot) {
        final users = snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();
        emit(state.copyWith(status: AdminStatus.success, users: users));
      },
      onError: (error) {
        emit(state.copyWith(status: AdminStatus.error, errorMessage: error.toString()));
      },
    );
  }

  void changeFilter(String newFilter) {
    emit(state.copyWith(filter: newFilter));
  }

  Future<void> toggleApprovalStatus(String uid, bool isApproved) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isApproved': !isApproved});
    } catch (e) {
      emit(state.copyWith(status: AdminStatus.error, errorMessage: 'فشل تحديث الحالة: $e'));
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      final batch = _firestore.batch();
      final userDocRef = _firestore.collection('users').doc(uid);
      final backupDocRef = _firestore.collection('backups').doc(uid);

      batch.delete(userDocRef);
      batch.delete(backupDocRef);

      await batch.commit();
    } catch (e) {
      emit(state.copyWith(status: AdminStatus.error, errorMessage: 'فشل حذف المستخدم: $e'));
    }
  }

  Future<void> setMaxDevices(String uid, int newMaxDevices) async {
    if (newMaxDevices < 1 || newMaxDevices > 10) {
      emit(state.copyWith(status: AdminStatus.error, errorMessage: 'الرقم يجب أن يكون بين 1 و 10'));
      return;
    }
    try {
      await _firestore.collection('users').doc(uid).update({'maxDevices': newMaxDevices});
    } catch (e) {
      emit(state.copyWith(status: AdminStatus.error, errorMessage: 'فشل تحديث عدد الأجهزة: $e'));
    }
  }

  Future<void> addDevice(String uid, String newDeviceId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'deviceIds': FieldValue.arrayUnion([newDeviceId])
      });
    } catch (e) {
      emit(state.copyWith(status: AdminStatus.error, errorMessage: 'فشل إضافة الجهاز: $e'));
    }
  }

  Future<void> removeDevice(String uid, String deviceId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'deviceIds': FieldValue.arrayRemove([deviceId])
      });
    } catch (e) {
      emit(state.copyWith(status: AdminStatus.error, errorMessage: 'فشل حذف الجهاز: $e'));
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}