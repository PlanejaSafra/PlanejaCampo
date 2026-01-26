// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parceiro.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ParceiroAdapter extends TypeAdapter<Parceiro> {
  @override
  final int typeId = 0;

  @override
  Parceiro read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Parceiro(
      id: fields[0] as String,
      nome: fields[1] as String,
      percentualPadrao: fields[2] as double,
      telefone: fields[3] as String?,
      tarefasIds: (fields[4] as List).cast<String>(),
      fotoPath: fields[5] as String?,
      farmId: fields[6] as String,
      createdBy: fields[7] as String,
      createdAt: fields[8] as DateTime,
      sourceApp: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Parceiro obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.percentualPadrao)
      ..writeByte(3)
      ..write(obj.telefone)
      ..writeByte(4)
      ..write(obj.tarefasIds)
      ..writeByte(5)
      ..write(obj.fotoPath)
      ..writeByte(6)
      ..write(obj.farmId)
      ..writeByte(7)
      ..write(obj.createdBy)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.sourceApp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParceiroAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
