// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receita.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceitaAdapter extends TypeAdapter<Receita> {
  @override
  final int typeId = 74;

  @override
  Receita read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Receita(
      id: fields[0] as String,
      valor: fields[1] as double,
      categoriaId: fields[2] as String,
      data: fields[3] as DateTime,
      descricao: fields[4] as String?,
      centroCustoId: fields[5] as String?,
      contaDestinoId: fields[6] as String?,
      farmId: fields[7] as String,
      createdBy: fields[8] as String,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[11] as DateTime,
      sourceApp: fields[10] as String,
      deleted: fields[12] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Receita obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.valor)
      ..writeByte(2)
      ..write(obj.categoriaId)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.descricao)
      ..writeByte(5)
      ..write(obj.centroCustoId)
      ..writeByte(6)
      ..write(obj.contaDestinoId)
      ..writeByte(7)
      ..write(obj.farmId)
      ..writeByte(8)
      ..write(obj.createdBy)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.sourceApp)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.deleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceitaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
