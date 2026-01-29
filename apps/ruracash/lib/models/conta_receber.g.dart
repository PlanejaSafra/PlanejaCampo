// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conta_receber.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContaReceberAdapter extends TypeAdapter<ContaReceber> {
  @override
  final int typeId = 81;

  @override
  ContaReceber read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContaReceber(
      id: fields[0] as String,
      descricao: fields[1] as String,
      valor: fields[2] as double,
      vencimento: fields[3] as DateTime,
      cliente: fields[4] as String?,
      categoriaId: fields[5] as String?,
      contaDestinoId: fields[6] as String?,
      status: fields[7] as StatusRecebimento,
      dataRecebimento: fields[8] as DateTime?,
      receitaOrigemId: fields[9] as String?,
      farmId: fields[10] as String,
      createdBy: fields[11] as String,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      sourceApp: fields[14] as String,
      deleted: fields[15] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, ContaReceber obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.descricao)
      ..writeByte(2)
      ..write(obj.valor)
      ..writeByte(3)
      ..write(obj.vencimento)
      ..writeByte(4)
      ..write(obj.cliente)
      ..writeByte(5)
      ..write(obj.categoriaId)
      ..writeByte(6)
      ..write(obj.contaDestinoId)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.dataRecebimento)
      ..writeByte(9)
      ..write(obj.receitaOrigemId)
      ..writeByte(10)
      ..write(obj.farmId)
      ..writeByte(11)
      ..write(obj.createdBy)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.sourceApp)
      ..writeByte(15)
      ..write(obj.deleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContaReceberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
