// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceInfoAdapter extends TypeAdapter<DeviceInfo> {
  @override
  final int typeId = 10;

  @override
  DeviceInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceInfo(
      platform: fields[0] as String,
      appVersion: fields[1] as String,
      deviceModel: fields[2] as String?,
      osVersion: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DeviceInfo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.platform)
      ..writeByte(1)
      ..write(obj.appVersion)
      ..writeByte(2)
      ..write(obj.deviceModel)
      ..writeByte(3)
      ..write(obj.osVersion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
