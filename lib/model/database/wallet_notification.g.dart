// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletNotificationAdapter extends TypeAdapter<WalletNotification> {
  @override
  final int typeId = 100;

  @override
  WalletNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletNotification(
      title: fields[0] as String?,
      timestamp: fields[1] as int?,
      details: fields[2] as String?,
      type: fields[3] as NotificationType?,
      id: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, WalletNotification obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.details)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
