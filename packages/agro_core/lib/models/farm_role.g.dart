// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farm_role.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FarmRoleAdapter extends TypeAdapter<FarmRole> {
  @override
  final int typeId = 23;

  @override
  FarmRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FarmRole.owner;
      case 1:
        return FarmRole.manager;
      case 2:
        return FarmRole.worker;
      default:
        return FarmRole.worker;
    }
  }

  @override
  void write(BinaryWriter writer, FarmRole obj) {
    switch (obj) {
      case FarmRole.owner:
        writer.writeByte(0);
        break;
      case FarmRole.manager:
        writer.writeByte(1);
        break;
      case FarmRole.worker:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
