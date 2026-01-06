import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/firebase_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState()) {
    fetchUserData();
  }

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchUserData() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final user = _auth.currentUser;

    if (user == null) {
      emit(state.copyWith(status: ProfileStatus.error, errorMessage: 'لا يوجد مستخدم مسجل الدخول.'));
      return;
    }

    try {
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      String? username;
      bool isAdmin = false;

      if (userDoc.exists) {
        username = userDoc.data()?['name'] ?? user.displayName;
        isAdmin =
            userDoc.data()?['isAdmin'] ?? false;
      } else {
        username = user.displayName;
      }

      emit(state.copyWith(
        status: ProfileStatus.success,
        firebaseUser: user,
        username: username,
        isAdmin: isAdmin,
      ));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.error, errorMessage: 'خطأ في جلب البيانات: $e'));
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'خطأ في تسجيل الخروج: $e'));
    }
  }

  Future<void> resetPassword() async {
    final email = state.firebaseUser?.email;
    if (email == null) {
      emit(state.copyWith(errorMessage: 'لا يوجد بريد إلكتروني صالح.'));
      return;
    }
    try {
      await _firebaseService.resetPassword(email);
      emit(state.copyWith(infoMessage: 'تم إرسال رابط إعادة تعيين كلمة المرور بنجاح.'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'فشل إرسال الرابط: $e'));
    }
  }

  Future<void> launchEmail() async {
    final emailUri = Uri(
        scheme: 'mailto',
        path: 'ahmedhassan24580@gmail.com',
        query: 'subject=ملاحظات حول التطبيق');
    if (!await launchUrl(emailUri)) {
      emit(state.copyWith(errorMessage: 'تعذر فتح تطبيق البريد الإلكتروني.'));
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearMessages: true));
  }
}
