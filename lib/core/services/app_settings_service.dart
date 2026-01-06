import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String _timeConflictHoursKey = 'time_conflict_hours';
  static const String _paymentDurationHoursKey = 'payment_duration_hours';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<SharedPreferences> get _instance async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  static Future<void> setTimeConflictHours(int hours) async {
    final prefs = await _instance;
    await prefs.setInt(_timeConflictHoursKey, hours);
  }

  static Future<int> getTimeConflictHours() async {
    final prefs = await _instance;
    return prefs.getInt(_timeConflictHoursKey) ?? 2;
  }

  static Future<void> setPaymentDurationHours(int hours) async {
    final prefs = await _instance;
    await prefs.setInt(_paymentDurationHoursKey, hours);
  }

  static Future<int> getPaymentDurationHours() async {
    final prefs = await _instance;
    return prefs.getInt(_paymentDurationHoursKey) ?? 24;
  }
}
