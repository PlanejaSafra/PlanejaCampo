// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'despesa.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DespesaAdapter extends TypeAdapter<Despesa> {
  @override
  final int typeId = 64;

  @override
  Despesa read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Despesa(
      id: fields[0] as String,
      valor: fields[1] as double,
      categoria: fields[2] as CategoriaDespesa,
      data: fields[3] as DateTime,
      descricao: fields[4] as String?,
      farmId: fields[5] as String,
      createdBy: fields[6] as String,
      createdAt: fields[7] as DateTime,
      sourceApp: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Despesa obj) {
    writer
      ..writeByte(9)
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
      other is DespesaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoriaDespesaAdapter extends TypeAdapter<CategoriaDespesa> {
  @override
  final int typeId = 63;

  @override
  CategoriaDespesa read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CategoriaDespesa.maoDeObra;
      case 1:
        return CategoriaDespesa.adubo;
      case 2:
        return CategoriaDespesa.defensivos;
      case 3:
        return CategoriaDespesa.combustivel;
      case 4:
        return CategoriaDespesa.manutencao;
      case 5:
        return CategoriaDespesa.outros;
      default:
        return CategoriaDespesa.maoDeObra;
    }
  }

  @override
  void write(BinaryWriter writer, CategoriaDespesa obj) {
    switch (obj) {
      case CategoriaDespesa.maoDeObra:
        writer.writeByte(0);
        break;
      case CategoriaDespesa.adubo:
        writer.writeByte(1);
        break;
      case CategoriaDespesa.defensivos:
        writer.writeByte(2);
        break;
      case CategoriaDespesa.combustivel:
        writer.writeByte(3);
        break;
      case CategoriaDespesa.manutencao:
        writer.writeByte(4);
        break;
      case CategoriaDespesa.outros:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoriaDespesaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
