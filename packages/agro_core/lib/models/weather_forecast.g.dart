// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_forecast.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeatherForecastAdapter extends TypeAdapter<WeatherForecast> {
  @override
  final int typeId = 3;

  @override
  WeatherForecast read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeatherForecast(
      date: fields[0] as DateTime,
      precipitationMm: fields[1] as double,
      temperatureMax: fields[2] as double,
      temperatureMin: fields[3] as double,
      weatherCode: fields[4] as int,
      cachedAt: fields[5] as DateTime,
      propertyId: fields[6] as String,
      windSpeed: fields[7] as double,
      windDirection: fields[8] as int,
      relativeHumidity: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WeatherForecast obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.precipitationMm)
      ..writeByte(2)
      ..write(obj.temperatureMax)
      ..writeByte(3)
      ..write(obj.temperatureMin)
      ..writeByte(4)
      ..write(obj.weatherCode)
      ..writeByte(5)
      ..write(obj.cachedAt)
      ..writeByte(6)
      ..write(obj.propertyId)
      ..writeByte(7)
      ..write(obj.windSpeed)
      ..writeByte(8)
      ..write(obj.windDirection)
      ..writeByte(9)
      ..write(obj.relativeHumidity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherForecastAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
