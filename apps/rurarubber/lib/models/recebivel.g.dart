// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recebivel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecebivelAdapter extends TypeAdapter<Recebivel> {
  @override
  final int typeId = 60;

  @override
  Recebivel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recebivel(
      id: fields[0] as String,
      entregaId: fields[1] as String,
      valor: fields[2] as double,
      dataPrevista: fields[3] as DateTime,
      dataRecebimento: fields[4] as DateTime?,
      compradorNome: fields[5] as String?,
      recebido: fields[6] as bool,
      farmId: fields[7] as String,
      createdBy: fields[8] as String,
      createdAt: fields[9] as DateTime,
      sourceApp: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Recebivel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entregaId)
      ..writeByte(2)
      ..write(obj.valor)
      ..writeByte(3)
      ..write(obj.dataPrevista)
      ..writeByte(4)
      ..write(obj.dataRecebimento)
      ..writeByte(5)
      ..write(obj.compradorNome)
      ..writeByte(6)
      ..write(obj.recebido)
      ..writeByte(7)
      ..write(obj.farmId)
      ..writeByte(8)
      ..write(obj.createdBy)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.sourceApp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecebivelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
