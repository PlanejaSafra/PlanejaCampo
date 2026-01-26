// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_categoria.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CashCategoriaAdapter extends TypeAdapter<CashCategoria> {
  @override
  final int typeId = 70;

  @override
  CashCategoria read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CashCategoria.maoDeObra;
      case 1:
        return CashCategoria.adubo;
      case 2:
        return CashCategoria.defensivos;
      case 3:
        return CashCategoria.combustivel;
      case 4:
        return CashCategoria.manutencao;
      case 5:
        return CashCategoria.energia;
      case 6:
        return CashCategoria.outros;
      default:
        return CashCategoria.maoDeObra;
    }
  }

  @override
  void write(BinaryWriter writer, CashCategoria obj) {
    switch (obj) {
      case CashCategoria.maoDeObra:
        writer.writeByte(0);
        break;
      case CashCategoria.adubo:
        writer.writeByte(1);
        break;
      case CashCategoria.defensivos:
        writer.writeByte(2);
        break;
      case CashCategoria.combustivel:
        writer.writeByte(3);
        break;
      case CashCategoria.manutencao:
        writer.writeByte(4);
        break;
      case CashCategoria.energia:
        writer.writeByte(5);
        break;
      case CashCategoria.outros:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashCategoriaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
