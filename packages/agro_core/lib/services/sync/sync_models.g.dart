// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineOperationAdapter extends TypeAdapter<OfflineOperation> {
  @override
  final int typeId = 33;

  @override
  OfflineOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineOperation(
      id: fields[0] as String,
      collection: fields[1] as String,
      operationType: fields[2] as OperationType,
      docId: fields[3] as String,
      data: (fields[4] as Map?)?.cast<String, dynamic>(),
      timestamp: fields[5] as DateTime,
      priority: fields[6] as OperationPriority,
      retryCount: fields[7] as int,
      lastError: fields[8] as String?,
      sourceApp: fields[9] as String?,
      farmId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineOperation obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.collection)
      ..writeByte(2)
      ..write(obj.operationType)
      ..writeByte(3)
      ..write(obj.docId)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.retryCount)
      ..writeByte(8)
      ..write(obj.lastError)
      ..writeByte(9)
      ..write(obj.sourceApp)
      ..writeByte(10)
      ..write(obj.farmId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OperationPriorityAdapter extends TypeAdapter<OperationPriority> {
  @override
  final int typeId = 31;

  @override
  OperationPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OperationPriority.critical;
      case 1:
        return OperationPriority.high;
      case 2:
        return OperationPriority.medium;
      case 3:
        return OperationPriority.low;
      default:
        return OperationPriority.critical;
    }
  }

  @override
  void write(BinaryWriter writer, OperationPriority obj) {
    switch (obj) {
      case OperationPriority.critical:
        writer.writeByte(0);
        break;
      case OperationPriority.high:
        writer.writeByte(1);
        break;
      case OperationPriority.medium:
        writer.writeByte(2);
        break;
      case OperationPriority.low:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OperationTypeAdapter extends TypeAdapter<OperationType> {
  @override
  final int typeId = 32;

  @override
  OperationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OperationType.create;
      case 1:
        return OperationType.update;
      case 2:
        return OperationType.delete;
      default:
        return OperationType.create;
    }
  }

  @override
  void write(BinaryWriter writer, OperationType obj) {
    switch (obj) {
      case OperationType.create:
        writer.writeByte(0);
        break;
      case OperationType.update:
        writer.writeByte(1);
        break;
      case OperationType.delete:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
