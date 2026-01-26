// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lancamento.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LancamentoAdapter extends TypeAdapter<Lancamento> {
  @override
  final int typeId = 71;

  @override
  Lancamento read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Lancamento(
      id: fields[0] as String,
      valor: fields[1] as double,
      categoria: fields[2] as CashCategoria,
      data: fields[3] as DateTime,
      descricao: fields[4] as String?,
      centroCustoId: fields[5] as String?,
      farmId: fields[6] as String,
      createdBy: fields[7] as String,
      createdAt: fields[8] as DateTime,
      sourceApp: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Lancamento obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.valor)
      ..writeByte(2)
      ..write(obj.categoria)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.descricao)
      ..writeByte(5)
      ..write(obj.centroCustoId)
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
      other is LancamentoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
