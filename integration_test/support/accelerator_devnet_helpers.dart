import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

AcceleratorDevnetContext? _activeAcceleratorContext;

/// Returns the active [AcceleratorDevnetContext] for the running scenario.
AcceleratorDevnetContext requireAcceleratorDevnetContext() {
  final AcceleratorDevnetContext? current = _activeAcceleratorContext;
  if (current == null) {
    throw StateError(
      'AcceleratorDevnetContext has not been initialized for this scenario',
    );
  }
  return current;
}

/// Manages scenario state and global teardown for the Accelerator-Z devnet BDD
/// integration test.
class AcceleratorDevnetContext {
  /// Creates and registers a fresh [AcceleratorDevnetContext] with teardown.
  factory AcceleratorDevnetContext.create() {
    _activeAcceleratorContext?.dispose();
    final AcceleratorDevnetContext context = AcceleratorDevnetContext._(
      savedSelectedAddress: kSelectedAddress,
      savedNumOfPillars: kNumOfPillars,
    );
    _activeAcceleratorContext = context;
    addTearDown(context.dispose);
    return context;
  }

  AcceleratorDevnetContext._({
    required this._savedSelectedAddress,
    required this._savedNumOfPillars,
  });

  final String? _savedSelectedAddress;
  final int? _savedNumOfPillars;
  bool _disposed = false;

  /// Devnet address that submitted the Accelerator-Z project.
  String? ownerAddress;

  /// Published `CreateProject` account block returned by `CreateProjectBloc`.
  AccountBlockTemplate? createProjectBlock;

  /// On-chain Accelerator-Z project identifier (`createProjectBlock.hash`).
  Hash? projectId;

  /// Confirmed on-chain [Project] fetched after submission.
  Project? submittedProject;

  /// Published producer vote block (`VoteByProdAddress`).
  AccountBlockTemplate? producerVoteBlock;

  /// Published owner vote block (`VoteByName`).
  AccountBlockTemplate? ownerVoteBlock;

  /// Restores wallet globals touched during the scenario.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    kSelectedAddress = _savedSelectedAddress;
    kNumOfPillars = _savedNumOfPillars;
    if (identical(_activeAcceleratorContext, this)) {
      _activeAcceleratorContext = null;
    }
  }
}
