// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class WalletNotificationAdapter extends TypeAdapter<WalletNotification> {
  @override
  final typeId = 100;

  @override
  WalletNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletNotification(
      title: fields[0] as String?,
      timestamp: (fields[1] as num?)?.toInt(),
      details: fields[2] as String?,
      type: fields[3] as NotificationType?,
      id: (fields[4] as num?)?.toInt(),
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

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final typeId = 101;

  @override
  NotificationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationType.paymentSent;
      case 1:
        return NotificationType.error;
      case 2:
        return NotificationType.stakingDeactivated;
      case 3:
        return NotificationType.paymentReceived;
      case 4:
        return NotificationType.autoLockIntervalChanged;
      case 5:
        return NotificationType.copiedToClipboard;
      case 6:
        return NotificationType.rewardReceived;
      case 7:
        return NotificationType.autoEraseNumAttemptsChanged;
      case 8:
        return NotificationType.generatingPlasma;
      case 9:
        return NotificationType.burnToken;
      case 10:
        return NotificationType.addedTokenFavourite;
      case 11:
        return NotificationType.removedTokenFavourite;
      case 12:
        return NotificationType.resetWallet;
      case 13:
        return NotificationType.changedNode;
      case 14:
        return NotificationType.delete;
      case 15:
        return NotificationType.confirm;
      default:
        return NotificationType.paymentSent;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.paymentSent:
        writer.writeByte(0);
      case NotificationType.error:
        writer.writeByte(1);
      case NotificationType.stakingDeactivated:
        writer.writeByte(2);
      case NotificationType.paymentReceived:
        writer.writeByte(3);
      case NotificationType.autoLockIntervalChanged:
        writer.writeByte(4);
      case NotificationType.copiedToClipboard:
        writer.writeByte(5);
      case NotificationType.rewardReceived:
        writer.writeByte(6);
      case NotificationType.autoEraseNumAttemptsChanged:
        writer.writeByte(7);
      case NotificationType.generatingPlasma:
        writer.writeByte(8);
      case NotificationType.burnToken:
        writer.writeByte(9);
      case NotificationType.addedTokenFavourite:
        writer.writeByte(10);
      case NotificationType.removedTokenFavourite:
        writer.writeByte(11);
      case NotificationType.resetWallet:
        writer.writeByte(12);
      case NotificationType.changedNode:
        writer.writeByte(13);
      case NotificationType.delete:
        writer.writeByte(14);
      case NotificationType.confirm:
        writer.writeByte(15);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
