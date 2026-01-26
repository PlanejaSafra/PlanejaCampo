// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tabela_sangria.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TabelaSangriaAdapter extends TypeAdapter<TabelaSangria> {
  @override
  final int typeId = 65;

  @override
  TabelaSangria read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TabelaSangria(
      id: fields[0] as String,
      parceiroId: fields[1] as String,
      numero: fields[2] as int,
      arvoresEstimadas: fields[3] as int?,
      lastTappedDate: fields[4] as DateTime?,
      farmId: fields[5] as String,
      createdBy: fields[6] as String,
      createdAt: fields[7] as DateTime,
      sourceApp: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TabelaSangria obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parceiroId)
      ..writeByte(2)
      ..write(obj.numero)
      ..writeByte(3)
      ..write(obj.arvoresEstimadas)
      ..writeByte(4)
      ..write(obj.lastTappedDate)
      ..writeByte(5)
      ..write(obj.farmId)
      ..writeByte(6)
      ..write(obj.createdBy)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.sourceApp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TabelaSangriaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
