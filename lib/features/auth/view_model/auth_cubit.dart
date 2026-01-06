import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthCubit(this._firebaseAuth, this._firestore) : super(AuthInitial());

  // التحقق من حالة المستخدم عند تشغيل التطبيق
  Future<void> checkAuthStatus() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      emit(const AuthUnauthenticated());
    } else {
      emit(AuthAuthenticated(user: user));
    }
  }

  // تسجيل الدخول
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        emit(AuthAuthenticated(user: userCredential.user!));
      }
    } on FirebaseAuthException catch (e) {
      // إرسال حالة الفشل مع الرسالة ليعرضها الـ LoginView
      emit(AuthUnauthenticated(message: _mapFirebaseAuthError(e.code), isError: true));
    } catch (e) {
      emit(const AuthUnauthenticated(message: 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.', isError: true));
    }
  }

  // إنشاء حساب جديد
  Future<void> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        try {
          // حفظ بيانات المستخدم الإضافية في Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': name,
            'phone': phone,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // تسجيل الخروج لإجبار المستخدم على الدخول بالبيانات الجديدة
          await _firebaseAuth.signOut();

          // إرسال رسالة النجاح
          emit(const AuthUnauthenticated(message: 'تم إنشاء الحساب بنجاح. الرجاء تسجيل الدخول.', isError: false));

        } on FirebaseException catch (e) {
          // في حال فشل الحفظ في Firestore، أظهر رسالة الخطأ الحقيقية
          emit(AuthUnauthenticated(message: 'حدث خطأ أثناء حفظ البيانات: ${e.message}', isError: true));
        }
      }
    } on FirebaseAuthException catch (e) {
      // إرسال الفشل ليعرضه الـ SignUpView كـ SnackBar
      emit(AuthUnauthenticated(message: _mapFirebaseAuthError(e.code), isError: true));
    } catch (e) {
      emit(const AuthUnauthenticated(message: 'حدث خطأ أثناء إنشاء الحساب، يرجى المحاولة لاحقاً.', isError: true));
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    emit(const AuthUnauthenticated());
  }

  // إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      emit(const AuthUnauthenticated(message: 'تم إرسال رابط إعادة تعيين كلمة المرور بنجاح.', isError: false));
    } on FirebaseAuthException catch (e) {
      emit(AuthUnauthenticated(message: _mapFirebaseAuthError(e.code), isError: true));
    } catch (e) {
      emit(const AuthUnauthenticated(message: 'حدث خطأ أثناء إرسال الرابط.', isError: true));
    }
  }

  // دالة مساعدة لإرسال فشل من خارج الكيوبت
  void emitFailure(String message) {
    emit(AuthUnauthenticated(message: message, isError: true));
  }

  // تحويل أكواد خطأ Firebase إلى رسائل عربية مفهومة
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'البيانات المدخلة غير صحيحة.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب. يرجى التواصل مع الدعم.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً. يرجى اختيار كلمة مرور أقوى.';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم بالفعل.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح بها. يرجى المحاولة لاحقًا.';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';
      default:
        return 'حدث خطأ في المصادقة، يرجى المحاولة مرة أخرى.';
    }
  }
}