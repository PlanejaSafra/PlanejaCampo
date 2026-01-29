// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conta_pagar.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContaPagarAdapter extends TypeAdapter<ContaPagar> {
  @override
  final int typeId = 80;

  @override
  ContaPagar read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContaPagar(
      id: fields[0] as String,
      descricao: fields[1] as String,
      valor: fields[2] as double,
      vencimento: fields[3] as DateTime,
      fornecedor: fields[4] as String?,
      categoriaId: fields[5] as String?,
      status: fields[6] as StatusPagamento,
      dataPagamento: fields[7] as DateTime?,
      lancamentoOrigemId: fields[8] as String?,
      contaPagamentoId: fields[9] as String?,
      parcela: fields[10] as int?,
      totalParcelas: fields[11] as int?,
      parcelaGrupoId: fields[12] as String?,
      farmId: fields[13] as String,
      createdBy: fields[14] as String,
      createdAt: fields[15] as DateTime,
      updatedAt: fields[16] as DateTime,
      sourceApp: fields[17] as String,
      deleted: fields[18] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, ContaPagar obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.descricao)
      ..writeByte(2)
      ..write(obj.valor)
      ..writeByte(3)
      ..write(obj.vencimento)
      ..writeByte(4)
      ..write(obj.fornecedor)
      ..writeByte(5)
      ..write(obj.categoriaId)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.dataPagamento)
      ..writeByte(8)
      ..write(obj.lancamentoOrigemId)
      ..writeByte(9)
      ..write(obj.contaPagamentoId)
      ..writeByte(10)
      ..write(obj.parcela)
      ..writeByte(11)
      ..write(obj.totalParcelas)
      ..writeByte(12)
      ..write(obj.parcelaGrupoId)
      ..writeByte(13)
      ..write(obj.farmId)
      ..writeByte(14)
      ..write(obj.createdBy)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.sourceApp)
      ..writeByte(18)
      ..write(obj.deleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContaPagarAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
