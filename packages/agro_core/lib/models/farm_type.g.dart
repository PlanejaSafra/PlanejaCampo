// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farm_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FarmTypeAdapter extends TypeAdapter<FarmType> {
  @override
  final int typeId = 21;

  @override
  FarmType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FarmType.agro;
      case 1:
        return FarmType.personal;
      default:
        return FarmType.agro;
    }
  }

  @override
  void write(BinaryWriter writer, FarmType obj) {
    switch (obj) {
      case FarmType.agro:
        writer.writeByte(0);
        break;
      case FarmType.personal:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
