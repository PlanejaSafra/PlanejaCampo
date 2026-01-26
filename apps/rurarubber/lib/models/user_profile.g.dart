// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 51;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      profileType: fields[0] as UserProfileType,
      displayName: fields[1] as String?,
      profileComplete: fields[2] as bool,
      createdAt: fields[3] as DateTime?,
      updatedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.profileType)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.profileComplete)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserProfileTypeAdapter extends TypeAdapter<UserProfileType> {
  @override
  final int typeId = 50;

  @override
  UserProfileType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserProfileType.produtor;
      case 1:
        return UserProfileType.comprador;
      case 2:
        return UserProfileType.sangrador;
      default:
        return UserProfileType.produtor;
    }
  }

  @override
  void write(BinaryWriter writer, UserProfileType obj) {
    switch (obj) {
      case UserProfileType.produtor:
        writer.writeByte(0);
        break;
      case UserProfileType.comprador:
        writer.writeByte(1);
        break;
      case UserProfileType.sangrador:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
