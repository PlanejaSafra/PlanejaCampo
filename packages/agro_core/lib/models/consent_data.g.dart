// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConsentDataAdapter extends TypeAdapter<ConsentData> {
  @override
  final int typeId = 11;

  @override
  ConsentData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConsentData(
      termsAccepted: fields[0] as bool,
      termsVersion: fields[1] as String,
      acceptedAt: fields[2] as DateTime,
      aggregateMetrics: fields[3] as bool?,
      sharePartners: fields[4] as bool?,
      adsPersonalization: fields[5] as bool?,
      regionalStats: fields[6] as bool?,
      cloudBackup: fields[8] as bool?,
      socialNetwork: fields[9] as bool?,
      consentVersion: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ConsentData obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.termsAccepted)
      ..writeByte(1)
      ..write(obj.termsVersion)
      ..writeByte(2)
      ..write(obj.acceptedAt)
      ..writeByte(3)
      ..write(obj.aggregateMetrics)
      ..writeByte(4)
      ..write(obj.sharePartners)
      ..writeByte(5)
      ..write(obj.adsPersonalization)
      ..writeByte(6)
      ..write(obj.regionalStats)
      ..writeByte(8)
      ..write(obj.cloudBackup)
      ..writeByte(9)
      ..write(obj.socialNetwork)
      ..writeByte(7)
      ..write(obj.consentVersion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsentDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
