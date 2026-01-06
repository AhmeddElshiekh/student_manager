// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentModelAdapter extends TypeAdapter<StudentModel> {
  @override
  final int typeId = 0;

  @override
  StudentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      studentNumber: fields[2] as String,
      parentNumber: fields[3] as String,
      studentClass: fields[4] as String,
      group: fields[5] as String,
      paymentHistory: (fields[6] as List?)?.cast<PaymentRecord>(),
      originalGroup: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StudentModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.studentNumber)
      ..writeByte(3)
      ..write(obj.parentNumber)
      ..writeByte(4)
      ..write(obj.studentClass)
      ..writeByte(5)
      ..write(obj.group)
      ..writeByte(6)
      ..write(obj.paymentHistory)
      ..writeByte(7)
      ..write(obj.originalGroup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
