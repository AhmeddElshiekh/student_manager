import 'package:hive/hive.dart';
import 'package:nizam/core/services/app_settings_service.dart';
import 'package:nizam/models/group_details_model.dart';

class ClassGroupService {
  static late Box<String> classBox;
  static late Box<GroupDetailsModel> groupDetailsBox;

  static Future<void> init() async {
    classBox = await Hive.openBox<String>('classes');
    groupDetailsBox = await Hive.openBox<GroupDetailsModel>('groups');
  }

  static List<String> getClasses() {
    return classBox.values.toList()..sort();
  }

  static Future<void> addClass(String className) async {
    if (!classBox.values.contains(className)) {
      await classBox.add(className);
    }
  }

  static String _mapIndexToOrdinal(int index) {
    switch (index) {
      case 1:
        return 'أولى';
      case 2:
        return 'ثانية';
      case 3:
        return 'ثالثة';
      case 4:
        return 'رابعة';
      case 5:
        return 'خامسة';
      case 6:
        return 'سادسة';
      default:
        return index.toString();
    }
  }

  static Future<void> addStageClasses(String stage) async {
    List<String> classesToAdd = [];
    switch (stage) {
      case 'ابتدائي':
        classesToAdd =
            List.generate(6, (i) => '${_mapIndexToOrdinal(i + 1)} ابتدائي');
        break;
      case 'إعدادي':
        classesToAdd =
            List.generate(3, (i) => '${_mapIndexToOrdinal(i + 1)} إعدادي');
        break;
      case 'ثانوي':
        classesToAdd =
            List.generate(3, (i) => '${_mapIndexToOrdinal(i + 1)} ثانوي');
        break;
    }
    for (var className in classesToAdd) {
      if (!classBox.values.contains(className)) {
        await classBox.add(className);
      }
    }
  }

  static Future<void> deleteClass(String className) async {
    final classKey = classBox.keys.firstWhere(
      (key) => classBox.get(key) == className,
      orElse: () => null,
    );
    if (classKey != null) {
      await classBox.delete(classKey);
    }
  }

  static DateTime? parseGroupDateTime(String groupString) {
    final parsed = _parseGroupString(groupString);
    if (parsed == null) return null;

    final Map<String, int> dayNamesToWeekdayIndex = {
      'الأحد': DateTime.sunday,
      'الاثنين': DateTime.monday,
      'الثلاثاء': DateTime.tuesday,
      'الأربعاء': DateTime.wednesday,
      'الخميس': DateTime.thursday,
      'الجمعة': DateTime.friday,
      'السبت': DateTime.saturday,
    };

    final targetWeekday = dayNamesToWeekdayIndex[parsed['day']];
    if (targetWeekday == null) return null;

    final int targetHour = parsed['hour'];
    final int targetMinute = parsed['minute'];

    final arbitraryMonday = DateTime(2024, 1, 1);

    final daysToAdd = (targetWeekday - arbitraryMonday.weekday + 7) % 7;

    final targetDate = arbitraryMonday.add(Duration(days: daysToAdd)).copyWith(
        hour: targetHour, minute: targetMinute, second: 0, millisecond: 0);

    return targetDate;
  }

  static Future<Map<String, dynamic>?> checkGroupTimeConflict(
      {required String newGroupString, String? excludeGroupKey}) async {
    final timeConflictHours = await AppSettingsService.getTimeConflictHours();

    final newGroupDateTime = parseGroupDateTime(newGroupString);
    if (newGroupDateTime == null) return null;

    for (var key in groupDetailsBox.keys) {
      if (key == excludeGroupKey) continue;
      final existingGroup = groupDetailsBox.get(key);
      if (existingGroup == null) continue;

      final existingGroupDateTime =
          parseGroupDateTime(existingGroup.groupDateTimeString);
      if (existingGroupDateTime == null) continue;

      if (newGroupDateTime.weekday == existingGroupDateTime.weekday) {
        final differenceInMinutes =
            newGroupDateTime.difference(existingGroupDateTime).inMinutes.abs();
        final conflictThresholdInMinutes = timeConflictHours * 60;

        if (differenceInMinutes < conflictThresholdInMinutes) {
          return {
            'conflictingGroup':
                '${existingGroup.className} - ${existingGroup.groupDateTimeString}',
          };
        }
      }
    }
    return null;
  }

  static String _convertArabicNumeralsToWestern(String input) {
    return input
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
  }

  static Map<String, dynamic>? _parseGroupString(String groupString) {
    final Map<String, int> dayIndexes = {
      'الاثنين': DateTime.monday,
      'الثلاثاء': DateTime.tuesday,
      'الأربعاء': DateTime.wednesday,
      'الخميس': DateTime.thursday,
      'الجمعة': DateTime.friday,
      'السبت': DateTime.saturday,
      'الأحد': DateTime.sunday,
    };
    try {
      final parts = groupString.split(' ');
      if (parts.length < 3) return null;
      final dayPart = parts[0];
      final timePart = parts[1];
      final amPmPart = parts[2];

      final dayIndex = dayIndexes[dayPart];
      if (dayIndex == null) return null;

      final westernTimePart = _convertArabicNumeralsToWestern(timePart);
      final timeParts = westernTimePart.split(':');

      if (timeParts.length < 2) return null;
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (amPmPart.toLowerCase() == 'م') {
        if (hour < 12) hour += 12;
      } else if (amPmPart.toLowerCase() == 'ص') {
        if (hour == 12) hour = 0;
      }

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

      final dayNames = {
        DateTime.monday: 'الاثنين',
        DateTime.tuesday: 'الثلاثاء',
        DateTime.wednesday: 'الأربعاء',
        DateTime.thursday: 'الخميس',
        DateTime.friday: 'الجمعة',
        DateTime.saturday: 'السبت',
        DateTime.sunday: 'الأحد',
      };

      return {
        'day': dayNames[dayIndex],
        'hour': hour,
        'minute': minute,
      };
    } catch (e) {
      return null;
    }
  }
}
