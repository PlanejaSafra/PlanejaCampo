// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registro_chuva.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RegistroChuvaAdapter extends TypeAdapter<RegistroChuva> {
  @override
  final int typeId = 1;

  @override
  RegistroChuva read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RegistroChuva(
      id: fields[0] as int,
      data: fields[1] as DateTime,
      milimetros: fields[2] as double,
      observacao: fields[3] as String?,
      criadoEm: fields[4] as DateTime,
      propertyId: fields[5] as String,
      talhaoId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RegistroChuva obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.milimetros)
      ..writeByte(3)
      ..write(obj.observacao)
      ..writeByte(4)
      ..write(obj.criadoEm)
      ..writeByte(5)
      ..write(obj.propertyId)
      ..writeByte(6)
      ..write(obj.talhaoId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistroChuvaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
