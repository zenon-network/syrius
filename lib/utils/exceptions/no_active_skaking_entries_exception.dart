import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';

/// Custom [Exception] to be used with [StakingCubit] when there are
/// no active staking entries found on an address
class NoActiveStakingEntriesException implements Exception {
  @override
  String toString() => 'No active staking entries';
}
