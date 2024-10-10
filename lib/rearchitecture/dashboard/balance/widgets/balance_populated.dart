import 'package:flutter/material.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A `BalancePopulated` widget that displays balance data once it has been
/// successfully fetched and populated.
///
/// This widget is displayed when the `BalanceCubit` is in the `success` state,
/// and the balance data is available for rendering.
class BalancePopulated extends StatelessWidget {
  /// The balance data that has been successfully fetched.
  ///
  /// The data is a map where the key is a string (representing the account address),
  /// and the value is an `AccountInfo` object containing the balance details.
  final Map<String, AccountInfo>? data;

  const BalancePopulated({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}
