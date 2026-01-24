// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_cloud_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserCloudDataAdapter extends TypeAdapter<UserCloudData> {
  @override
  final int typeId = 12;

  @override
  UserCloudData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserCloudData(
      uid: fields[0] as String,
      createdAt: fields[1] as DateTime,
      lastActive: fields[2] as DateTime,
      deviceInfo: fields[3] as DeviceInfo,
      consents: fields[4] as ConsentData,
      lastSyncedAt: fields[5] as DateTime?,
      syncEnabled: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserCloudData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.lastActive)
      ..writeByte(3)
      ..write(obj.deviceInfo)
      ..writeByte(4)
      ..write(obj.consents)
      ..writeByte(5)
      ..write(obj.lastSyncedAt)
      ..writeByte(6)
      ..write(obj.syncEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCloudDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
