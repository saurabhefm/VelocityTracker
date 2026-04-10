// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripStatusAdapter extends TypeAdapter<TripStatus> {
  @override
  final int typeId = 1;

  @override
  TripStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TripStatus.idle;
      case 1:
        return TripStatus.tracking;
      case 2:
        return TripStatus.paused;
      default:
        return TripStatus.idle;
    }
  }

  @override
  void write(BinaryWriter writer, TripStatus obj) {
    switch (obj) {
      case TripStatus.idle:
        writer.writeByte(0);
        break;
      case TripStatus.tracking:
        writer.writeByte(1);
        break;
      case TripStatus.paused:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
