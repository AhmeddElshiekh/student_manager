import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceLimitException implements Exception {
  final String message;

  DeviceLimitException(this.message);

  @override
  String toString() => 'DeviceLimitException: $message';
}

class UnapprovedUserException implements Exception {
  final String message;

  UnapprovedUserException(this.message);

  @override
  String toString() => 'UnapprovedUserException: $message';
}

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw Exception('فشل في الحصول على بيانات المستخدم بعد تسجيل الدخول.');
      }

      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc =
          await userDocRef.get(const GetOptions(source: Source.server));

      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception('بيانات هذا الحساب غير موجودة في قاعدة البيانات.');
      }


    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user == null) {
      throw Exception('فشل في إنشاء المستخدم.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'email': email,
      'name': name,
      'phone': phone,

    });

    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('لا يوجد حساب بهذا البريد الإلكتروني.');
      }
      throw Exception('حدث خطأ أثناء إعادة تعيين كلمة المرور.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
