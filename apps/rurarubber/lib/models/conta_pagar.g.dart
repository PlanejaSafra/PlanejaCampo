// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conta_pagar.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContaPagarAdapter extends TypeAdapter<ContaPagar> {
  @override
  final int typeId = 62;

  @override
  ContaPagar read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContaPagar(
      id: fields[0] as String,
      parceiroId: fields[1] as String,
      entregaId: fields[2] as String?,
      valor: fields[3] as double,
      vencimento: fields[4] as DateTime,
      pago: fields[5] as bool,
      dataPagamento: fields[6] as DateTime?,
      formaPagamento: fields[7] as FormaPagamento?,
      farmId: fields[8] as String,
      createdBy: fields[9] as String,
      createdAt: fields[10] as DateTime,
      sourceApp: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ContaPagar obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parceiroId)
      ..writeByte(2)
      ..write(obj.entregaId)
      ..writeByte(3)
      ..write(obj.valor)
      ..writeByte(4)
      ..write(obj.vencimento)
      ..writeByte(5)
      ..write(obj.pago)
      ..writeByte(6)
      ..write(obj.dataPagamento)
      ..writeByte(7)
      ..write(obj.formaPagamento)
      ..writeByte(8)
      ..write(obj.farmId)
      ..writeByte(9)
      ..write(obj.createdBy)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.sourceApp);
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

class FormaPagamentoAdapter extends TypeAdapter<FormaPagamento> {
  @override
  final int typeId = 61;

  @override
  FormaPagamento read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FormaPagamento.pix;
      case 1:
        return FormaPagamento.ted;
      case 2:
        return FormaPagamento.dinheiro;
      default:
        return FormaPagamento.pix;
    }
  }

  @override
  void write(BinaryWriter writer, FormaPagamento obj) {
    switch (obj) {
      case FormaPagamento.pix:
        writer.writeByte(0);
        break;
      case FormaPagamento.ted:
        writer.writeByte(1);
        break;
      case FormaPagamento.dinheiro:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormaPagamentoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
