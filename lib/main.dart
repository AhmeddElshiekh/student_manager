import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studentmanager/features/auth/view/auth_wrapper.dart';
import 'package:studentmanager/features/settings/view_model/settings_cubit.dart';
import 'package:studentmanager/features/settings/view_model/settings_state.dart';
import 'package:studentmanager/core/services/ClassGroupService.dart';
import 'package:studentmanager/core/services/firebase_backup_service.dart';
import 'package:studentmanager/core/theme/app_theme.dart';
import 'package:studentmanager/firebase_options.dart';
import 'package:studentmanager/models/group_details_model.dart';
import 'package:studentmanager/models/payment_record_model.dart';
import 'package:studentmanager/models/student_model.dart';
import 'package:workmanager/workmanager.dart';
import 'features/auth/view_model/auth_cubit.dart';
import 'package:studentmanager/core/services/auto_sync_service.dart';

const simplePeriodicTask = "com.studentmanager.backupTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();
      await Hive.initFlutter();

      Hive.registerAdapter(StudentModelAdapter());
      Hive.registerAdapter(PaymentRecordAdapter());
      Hive.registerAdapter(GroupDetailsModelAdapter());

      if (!Hive.isBoxOpen('students'))
        await Hive.openBox<StudentModel>('students');
      if (!Hive.isBoxOpen('groups'))
        await Hive.openBox<GroupDetailsModel>('groups');
      if (!Hive.isBoxOpen('classes')) await Hive.openBox<String>('classes');
      if (!Hive.isBoxOpen('settings')) await Hive.openBox('settings');

      final service = FirebaseBackupService();
      await service.uploadBackup(merge: true);
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}
// أضف هذا الكلاس في نفس الملف (خارج أي كلاس آخر)
class _LifecycleWatcher extends StatefulWidget {
  final Widget child;
  const _LifecycleWatcher({required this.child});

  @override
  State<_LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<_LifecycleWatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // عندما يعود التطبيق إلى الواجهة، قم بجلب التحديثات
      AutoSyncService.instance.syncDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(StudentModelAdapter());
  Hive.registerAdapter(PaymentRecordAdapter());
  Hive.registerAdapter(GroupDetailsModelAdapter());

  Workmanager().initialize(callbackDispatcher);

  if (!Hive.isBoxOpen('students')) await Hive.openBox<StudentModel>('students');
  if (!Hive.isBoxOpen('groups'))
    await Hive.openBox<GroupDetailsModel>('groups');
  if (!Hive.isBoxOpen('classes')) await Hive.openBox<String>('classes');
  if (!Hive.isBoxOpen('settings')) await Hive.openBox('settings');
  await AutoSyncService.instance.initialize();
  
  await ClassGroupService.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsCubit(),
        ),
        BlocProvider(
          create: (context) => AuthCubit(
            FirebaseAuth.instance,
            FirebaseFirestore.instance,
          )..checkAuthStatus(),
        ),
      ],
      child: const SmartStudentAppWithBackup(),
    ),
  );
}

class SmartStudentAppWithBackup extends StatelessWidget {
  const SmartStudentAppWithBackup({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (_, state) {
        final themeMode = switch (state.themeMode) {
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
          AppThemeMode.system => ThemeMode.system,
        };

        return _LifecycleWatcher(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Smart Student',
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthWrapper(), // The one true gatekeeper
          ),
        );
      },
    );
  }
}
