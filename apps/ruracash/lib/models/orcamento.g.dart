// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orcamento.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrcamentoAdapter extends TypeAdapter<Orcamento> {
  @override
  final int typeId = 82;

  @override
  Orcamento read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Orcamento(
      id: fields[0] as String,
      categoriaId: fields[1] as String,
      valorLimite: fields[2] as double,
      tipo: fields[3] as TipoPeriodoOrcamento,
      ano: fields[4] as int,
      mes: fields[5] as int?,
      trimestre: fields[6] as int?,
      alertaAtivo: fields[7] as bool,
      alertaPercentual: fields[8] as int,
      farmId: fields[9] as String,
      createdBy: fields[10] as String,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      sourceApp: fields[13] as String,
      deleted: fields[14] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Orcamento obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoriaId)
      ..writeByte(2)
      ..write(obj.valorLimite)
      ..writeByte(3)
      ..write(obj.tipo)
      ..writeByte(4)
      ..write(obj.ano)
      ..writeByte(5)
      ..write(obj.mes)
      ..writeByte(6)
      ..write(obj.trimestre)
      ..writeByte(7)
      ..write(obj.alertaAtivo)
      ..writeByte(8)
      ..write(obj.alertaPercentual)
      ..writeByte(9)
      ..write(obj.farmId)
      ..writeByte(10)
      ..write(obj.createdBy)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.sourceApp)
      ..writeByte(14)
      ..write(obj.deleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrcamentoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TipoPeriodoOrcamentoAdapter extends TypeAdapter<TipoPeriodoOrcamento> {
  @override
  final int typeId = 83;

  @override
  TipoPeriodoOrcamento read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TipoPeriodoOrcamento.mes;
      case 1:
        return TipoPeriodoOrcamento.trimestre;
      case 2:
        return TipoPeriodoOrcamento.safra;
      case 3:
        return TipoPeriodoOrcamento.ano;
      default:
        return TipoPeriodoOrcamento.mes;
    }
  }

  @override
  void write(BinaryWriter writer, TipoPeriodoOrcamento obj) {
    switch (obj) {
      case TipoPeriodoOrcamento.mes:
        writer.writeByte(0);
        break;
      case TipoPeriodoOrcamento.trimestre:
        writer.writeByte(1);
        break;
      case TipoPeriodoOrcamento.safra:
        writer.writeByte(2);
        break;
      case TipoPeriodoOrcamento.ano:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipoPeriodoOrcamentoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
