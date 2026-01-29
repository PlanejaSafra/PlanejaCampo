// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conta.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContaAdapter extends TypeAdapter<Conta> {
  @override
  final int typeId = 73;

  @override
  Conta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Conta(
      id: fields[0] as String,
      nome: fields[1] as String,
      tipo: fields[2] as TipoConta,
      saldoInicial: fields[3] as double,
      saldoAtual: fields[4] as double,
      banco: fields[5] as String?,
      agencia: fields[6] as String?,
      numeroConta: fields[7] as String?,
      corValue: fields[8] as int,
      isAtiva: fields[9] as bool,
      farmId: fields[10] as String,
      createdBy: fields[11] as String,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[14] as DateTime,
      sourceApp: fields[13] as String,
      deleted: fields[15] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Conta obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.tipo)
      ..writeByte(3)
      ..write(obj.saldoInicial)
      ..writeByte(4)
      ..write(obj.saldoAtual)
      ..writeByte(5)
      ..write(obj.banco)
      ..writeByte(6)
      ..write(obj.agencia)
      ..writeByte(7)
      ..write(obj.numeroConta)
      ..writeByte(8)
      ..write(obj.corValue)
      ..writeByte(9)
      ..write(obj.isAtiva)
      ..writeByte(10)
      ..write(obj.farmId)
      ..writeByte(11)
      ..write(obj.createdBy)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.sourceApp)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.deleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TipoContaAdapter extends TypeAdapter<TipoConta> {
  @override
  final int typeId = 75;

  @override
  TipoConta read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TipoConta.carteira;
      case 1:
        return TipoConta.contaCorrente;
      case 2:
        return TipoConta.poupanca;
      case 3:
        return TipoConta.cartaoCredito;
      case 4:
        return TipoConta.investimento;
      case 5:
        return TipoConta.emprestimo;
      default:
        return TipoConta.carteira;
    }
  }

  @override
  void write(BinaryWriter writer, TipoConta obj) {
    switch (obj) {
      case TipoConta.carteira:
        writer.writeByte(0);
        break;
      case TipoConta.contaCorrente:
        writer.writeByte(1);
        break;
      case TipoConta.poupanca:
        writer.writeByte(2);
        break;
      case TipoConta.cartaoCredito:
        writer.writeByte(3);
        break;
      case TipoConta.investimento:
        writer.writeByte(4);
        break;
      case TipoConta.emprestimo:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipoContaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
