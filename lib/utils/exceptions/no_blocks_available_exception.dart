import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';

/// Custom [Exception] to be used with [RealtimeStatisticsCubit] when there are
/// no account blocks available on the network
class NoBlocksAvailableException implements Exception {
  @override
  String toString() => 'No account blocks available';
}
