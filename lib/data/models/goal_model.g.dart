// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalModelAdapter extends TypeAdapter<GoalModel> {
  @override
  final int typeId = 0;

  @override
  GoalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalModel(
      id: fields[0] as String,
      name: fields[1] as String,
      targetAmount: fields[2] as double,
      deadline: fields[3] as DateTime?,
      savedAmount: fields[4] as double,
      iconCodePoint: fields[5] as int,
      colorValue: fields[6] as int,
      isArchived: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      reminderTime: fields[9] as String?,
      note: fields[10] as String?,
      rhythm: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GoalModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.deadline)
      ..writeByte(4)
      ..write(obj.savedAmount)
      ..writeByte(5)
      ..write(obj.iconCodePoint)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.isArchived)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.reminderTime)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.rhythm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
