// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safra.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SafraAdapter extends TypeAdapter<Safra> {
  @override
  final int typeId = 21;

  @override
  Safra read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Safra(
      id: fields[0] as String,
      farmId: fields[1] as String,
      nome: fields[2] as String,
      dataInicio: fields[3] as DateTime,
      dataFim: fields[4] as DateTime?,
      ativa: fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Safra obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.farmId)
      ..writeByte(2)
      ..write(obj.nome)
      ..writeByte(3)
      ..write(obj.dataInicio)
      ..writeByte(4)
      ..write(obj.dataFim)
      ..writeByte(5)
      ..write(obj.ativa)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafraAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
