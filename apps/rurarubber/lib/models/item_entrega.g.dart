// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_entrega.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemEntregaAdapter extends TypeAdapter<ItemEntrega> {
  @override
  final int typeId = 1;

  @override
  ItemEntrega read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemEntrega(
      parceiroId: fields[0] as String,
      pesagens: (fields[1] as List).cast<double>(),
      pesoTotal: fields[2] as double,
      valorTotal: fields[3] as double,
      descontos: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ItemEntrega obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.parceiroId)
      ..writeByte(1)
      ..write(obj.pesagens)
      ..writeByte(2)
      ..write(obj.pesoTotal)
      ..writeByte(3)
      ..write(obj.valorTotal)
      ..writeByte(4)
      ..write(obj.descontos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemEntregaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
