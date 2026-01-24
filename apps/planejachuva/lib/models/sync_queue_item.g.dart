// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncQueueItemAdapter extends TypeAdapter<SyncQueueItem> {
  @override
  final int typeId = 4;

  @override
  SyncQueueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncQueueItem(
      registroId: fields[0] as int,
      date: fields[1] as DateTime,
      millimeters: fields[2] as double,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      geoHash5: fields[5] as String,
      propertyId: fields[6] as String,
      queuedAt: fields[7] as DateTime,
      attempts: fields[8] as int,
      lastError: fields[9] as String?,
      shouldRetry: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.registroId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.millimeters)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.geoHash5)
      ..writeByte(6)
      ..write(obj.propertyId)
      ..writeByte(7)
      ..write(obj.queuedAt)
      ..writeByte(8)
      ..write(obj.attempts)
      ..writeByte(9)
      ..write(obj.lastError)
      ..writeByte(10)
      ..write(obj.shouldRetry);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
