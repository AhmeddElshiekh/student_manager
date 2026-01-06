// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_details_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupDetailsModelAdapter extends TypeAdapter<GroupDetailsModel> {
  @override
  final int typeId = 4;

  @override
  GroupDetailsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupDetailsModel(
      className: fields[0] as String,
      groupDateTimeString: fields[1] as String,
      pricePerStudent: fields[2] as double,
      groupId: fields[3] as String,
      members: (fields[4] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, GroupDetailsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.className)
      ..writeByte(1)
      ..write(obj.groupDateTimeString)
      ..writeByte(2)
      ..write(obj.pricePerStudent)
      ..writeByte(3)
      ..write(obj.groupId)
      ..writeByte(4)
      ..write(obj.members);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupDetailsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
