import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';

/// Custom [Exception] to be used with [TotalHourlyTransactionsCubit] when
/// the network is less than one hour old
class NotEnoughMomentumsException implements Exception {
  @override
  String toString() => 'Not enough momentums';
}
