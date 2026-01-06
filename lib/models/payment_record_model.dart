import 'package:hive/hive.dart';
part 'payment_record_model.g.dart';

@HiveType(typeId: 2)
class PaymentRecord extends HiveObject {
  @HiveField(0)
  late DateTime date;
  @HiveField(1)
  late bool isPaid;
  @HiveField(2)
  DateTime? paymentExpiresAt;
  @HiveField(3)
  late String paymentMethod;
  @HiveField(4)
  String? cancellationReason;

  PaymentRecord({
    required this.date,
    required this.isPaid,
    this.paymentExpiresAt,
    required this.paymentMethod,
    this.cancellationReason,
  });


  bool get isActive => isPaid && paymentExpiresAt != null && paymentExpiresAt!.isAfter(DateTime.now());


  void cancel(String reason) {
    if (isActive) {
      isPaid = false;
      cancellationReason = reason;

    }
  }


  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'isPaid': isPaid,
      'paymentExpiresAt': paymentExpiresAt?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'cancellationReason': cancellationReason,
    };
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      date: DateTime.parse(json['date'] as String),
      isPaid: json['isPaid'] as bool,
      paymentExpiresAt: json['paymentExpiresAt'] != null
          ? DateTime.parse(json['paymentExpiresAt'] as String)
          : null,
      paymentMethod: json['paymentMethod'] as String,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }
}
