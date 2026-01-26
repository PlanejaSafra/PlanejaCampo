// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entrega.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EntregaAdapter extends TypeAdapter<Entrega> {
  @override
  final int typeId = 2;

  @override
  Entrega read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Entrega(
      id: fields[0] as String,
      data: fields[1] as DateTime,
      status: fields[2] as String,
      precoDrc: fields[3] as double?,
      precoUmido: fields[4] as double?,
      compradorId: fields[5] as String?,
      itens: (fields[6] as List).cast<ItemEntrega>(),
      farmId: fields[7] as String,
      createdBy: fields[8] as String,
      createdAt: fields[9] as DateTime,
      sourceApp: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Entrega obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.precoDrc)
      ..writeByte(4)
      ..write(obj.precoUmido)
      ..writeByte(5)
      ..write(obj.compradorId)
      ..writeByte(6)
      ..write(obj.itens)
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
      other is EntregaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
