// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transferencia.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransferenciaAdapter extends TypeAdapter<Transferencia> {
  @override
  final int typeId = 79;

  @override
  Transferencia read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transferencia(
      id: fields[0] as String,
      contaOrigemId: fields[1] as String,
      contaDestinoId: fields[2] as String,
      valor: fields[3] as double,
      data: fields[4] as DateTime,
      descricao: fields[5] as String?,
      farmId: fields[6] as String,
      createdBy: fields[7] as String,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[10] as DateTime,
      sourceApp: fields[9] as String,
      deleted: fields[11] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Transferencia obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.contaOrigemId)
      ..writeByte(2)
      ..write(obj.contaDestinoId)
      ..writeByte(3)
      ..write(obj.valor)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.descricao)
      ..writeByte(6)
      ..write(obj.farmId)
      ..writeByte(7)
      ..write(obj.createdBy)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.sourceApp)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.deleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferenciaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
