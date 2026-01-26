// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_manifest.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DependencyManifestAdapter extends TypeAdapter<DependencyManifest> {
  @override
  final int typeId = 30;

  @override
  DependencyManifest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DependencyManifest(
      appId: fields[0] as String,
      references: (fields[1] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      updatedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DependencyManifest obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.appId)
      ..writeByte(1)
      ..write(obj.references)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DependencyManifestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
