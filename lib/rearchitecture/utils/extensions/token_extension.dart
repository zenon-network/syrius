import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// An extension that adds functionality to the [Token] class
extension TokenExtension on Token {
  /// Whether a [Token] is a coin - ZNN, QSR - or an user-made token
  bool get isCoin => <TokenStandard>[znnZts, qsrZts].contains(tokenStandard);
}
