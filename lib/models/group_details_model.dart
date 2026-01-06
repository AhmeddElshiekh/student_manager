
import 'package:hive/hive.dart';
part 'group_details_model.g.dart';

@HiveType(typeId: 4)
class GroupDetailsModel extends HiveObject {
  @HiveField(0)
  final String className;

  @HiveField(1)
  final String groupDateTimeString;

  @HiveField(2)
  double pricePerStudent;

  @HiveField(3)
  final String groupId;

  @HiveField(4)
  List<String> members;

  GroupDetailsModel({
    required this.className,
    required this.groupDateTimeString,
    required this.pricePerStudent,
    required this.groupId,
    List<String>? members,
  }) : members = members ?? [];

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'groupDateTimeString': groupDateTimeString,
      'pricePerStudent': pricePerStudent,
      'groupId': groupId,
      'members': members,
    };
  }

  factory GroupDetailsModel.fromJson(Map<String, dynamic> json) {
    return GroupDetailsModel(
      className: json['className'] as String,
      groupDateTimeString: json['groupDateTimeString'] as String,
      pricePerStudent: (json['pricePerStudent'] as num).toDouble(),
      groupId: json['groupId'] as String,
      members: json['members'] != null ? List<String>.from(json['members'] as List) : [],
    );
  }
}
