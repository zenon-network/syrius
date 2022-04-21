// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = 101;

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
      default:
        return NotificationType.paymentSent;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.paymentSent:
        writer.writeByte(0);
        break;
      case NotificationType.error:
        writer.writeByte(1);
        break;
      case NotificationType.stakingDeactivated:
        writer.writeByte(2);
        break;
      case NotificationType.paymentReceived:
        writer.writeByte(3);
        break;
      case NotificationType.autoLockIntervalChanged:
        writer.writeByte(4);
        break;
      case NotificationType.copiedToClipboard:
        writer.writeByte(5);
        break;
      case NotificationType.rewardReceived:
        writer.writeByte(6);
        break;
      case NotificationType.autoEraseNumAttemptsChanged:
        writer.writeByte(7);
        break;
      case NotificationType.generatingPlasma:
        writer.writeByte(8);
        break;
      case NotificationType.burnToken:
        writer.writeByte(9);
        break;
      case NotificationType.addedTokenFavourite:
        writer.writeByte(10);
        break;
      case NotificationType.removedTokenFavourite:
        writer.writeByte(11);
        break;
      case NotificationType.resetWallet:
        writer.writeByte(12);
        break;
      case NotificationType.changedNode:
        writer.writeByte(13);
        break;
      case NotificationType.delete:
        writer.writeByte(14);
        break;
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
