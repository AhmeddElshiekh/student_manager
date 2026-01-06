import 'package:hive/hive.dart';
part 'attendance_record_model.g.dart';

@HiveType(typeId: 3)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final bool isPresent;

  AttendanceRecord({
    required this.date,
    required this.isPresent,
  });
}
