
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:nizam/models/payment_record_model.dart';
part 'student_model.g.dart';

@HiveType(typeId: 0)
class StudentModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String studentNumber;

  @HiveField(3)
  late String parentNumber;

  @HiveField(4)
  late String studentClass;

  @HiveField(5)
  late String group;

  @HiveField(6)
  late List<PaymentRecord> paymentHistory;

  @HiveField(7)
  String? originalGroup;

  static final _uuid = const Uuid();

  StudentModel({
    String? id,
    required this.name,
    required this.studentNumber,
    required this.parentNumber,
    required this.studentClass,
    required this.group,
    List<PaymentRecord>? paymentHistory,
    this.originalGroup,

  }) : this.id = id ?? _uuid.v4(),
        this.paymentHistory = paymentHistory ?? [];


  String get paymentStatus {
    if (paymentHistory.isEmpty) {
      return 'notPaid';
    }

    final lastRecord = paymentHistory.last;

    if (lastRecord.isPaid && lastRecord.paymentExpiresAt != null && lastRecord.paymentExpiresAt!.isAfter(DateTime.now())) {
      return 'paid';
    }


    if (lastRecord.paymentMethod == 'مؤجل') {
      return 'postponed';
    }

    return 'notPaid';
  }

  bool get isPaid {
    return paymentStatus == 'paid';
  }

  bool get hasNeverPaidBefore {
    return paymentHistory.every((record) => !record.isPaid);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'studentNumber': studentNumber,
      'parentNumber': parentNumber,
      'studentClass': studentClass,
      'group': group,
      'paymentHistory': paymentHistory.map((e) => e.toJson()).toList(),
      'originalGroup': originalGroup,

    };
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      studentNumber: json['studentNumber'] as String,
      parentNumber: json['parentNumber'] as String,
      studentClass: json['studentClass'] as String,
      group: json['group'] as String,
      paymentHistory: (json['paymentHistory'] as List<dynamic>?)
          ?.map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      originalGroup: json['originalGroup'] as String?,

    );
  }

  StudentModel copyWith({
    String? id,
    String? name,
    String? studentNumber,
    String? parentNumber,
    String? studentClass,
    String? group,
    List<PaymentRecord>? paymentHistory,
    String? originalGroup,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      studentNumber: studentNumber ?? this.studentNumber,
      parentNumber: parentNumber ?? this.parentNumber,
      studentClass: studentClass ?? this.studentClass,
      group: group ?? this.group,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      originalGroup: originalGroup ?? this.originalGroup,
    );
  }
  StudentModel.empty()
      : id = '',
        name = '',
        studentNumber = '',
        parentNumber = '',
        studentClass = '',
        group = '',
        paymentHistory = [];

  bool get isEmptyStudent => id.isEmpty;
}
