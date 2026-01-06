import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studentmanager/features/auth/view_model/auth_cubit.dart';
import 'package:studentmanager/features/payments/view/payments_view.dart';
import 'package:studentmanager/features/settings/view/settings_view.dart';
import 'package:studentmanager/features/statistics/view/statistics_view.dart';
import 'package:studentmanager/features/students/view/classes_list_view.dart';
import 'package:studentmanager/features/students/view/student_qr_view.dart';
import 'package:studentmanager/features/user/view/user_view.dart';
import 'core/navigation/app_router.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int currentIndex = 0;
  DateTime? _lastPressedAt;

  final List<Widget> screens = const [
    ClassesListView(),
    PaymentsView(),
    StatisticsView(),
    SettingsView(),
    UserProfileView(),
  ];

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserListener();
    });
  }

  Future<void> _initializeUserListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.read<AuthCubit>().logout();
      return;
    }

    await _userSubscription?.cancel();

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (mounted && !snapshot.exists) {
          _performSafeSignOut(message: 'تم تسجيل خروجك لأن حسابك قد تم حذفه.');
        }
      },
      onError: (error) {
        if (mounted) {
          _performSafeSignOut(message: 'حدث خطأ أثناء الاتصال، تم تسجيل خروجك.');
        }
      },
    );
  }

  Future<void> _performSafeSignOut({String? message}) async {
    await _userSubscription?.cancel();
    await context.read<AuthCubit>().logout();
    // لا Navigation هنا
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (currentIndex == 0) {
          if (_lastPressedAt == null ||
              DateTime.now().difference(_lastPressedAt!) >
                  const Duration(seconds: 2)) {
            _lastPressedAt = DateTime.now();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('اضغط مرة أخرى للخروج من التطبيق.'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            SystemNavigator.pop();
          }
        } else {
          setState(() {
            currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Manager'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                AppRouter.pushWithScaleTransition(
                  context,
                  const QRScannerView(),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                );
              },
              tooltip: 'مسح QR Code',
            ),

          ],
        ),
        body: screens[currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'الطلاب'),
            BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'سجل الدفع'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: 'الإحصائيات'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'الإعدادات'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}
