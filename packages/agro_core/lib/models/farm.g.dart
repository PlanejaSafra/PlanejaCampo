// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farm.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FarmAdapter extends TypeAdapter<Farm> {
  @override
  final int typeId = 20;

  @override
  Farm read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Farm(
      id: fields[0] as String,
      name: fields[1] as String,
      ownerId: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      isDefault: fields[5] as bool,
      description: fields[6] as String?,
      subscriptionTier: fields[8] as String?,
      isShared: fields[9] as bool,
      type: fields[10] as FarmType,
    );
  }

  @override
  void write(BinaryWriter writer, Farm obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ownerId)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.isDefault)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.subscriptionTier)
      ..writeByte(9)
      ..write(obj.isShared)
      ..writeByte(10)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
