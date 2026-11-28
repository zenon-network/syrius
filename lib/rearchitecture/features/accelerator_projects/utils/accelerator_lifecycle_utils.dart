import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Returns whether [ownerZnnBalance] covers [projectCreationFeeInZnn].
bool hasSufficientProjectCreationFee(BigInt ownerZnnBalance) =>
    ownerZnnBalance >= projectCreationFeeInZnn;

/// Returns whether a new Accelerator-Z project satisfies the creation fee and
/// ZNN/QSR funding floor and ceiling bounds.
bool isValidAcceleratorProjectBudget({
  required BigInt ownerZnnBalance,
  required BigInt znnNeeded,
  required BigInt qsrNeeded,
}) =>
    hasSufficientProjectCreationFee(ownerZnnBalance) &&
    znnNeeded >= kZnnProjectMinimumFunds &&
    znnNeeded <= kZnnProjectMaximumFunds &&
    qsrNeeded >= kQsrProjectMinimumFunds &&
    qsrNeeded <= kQsrProjectMaximumFunds;

/// Returns whether [selectedAddress] can create a new phase for [project].
///
/// Requires [selectedAddress] to match [project]'s owner, [project] to be
/// [AcceleratorProjectStatus.active], and either no existing phases or the
/// latest phase already [AcceleratorProjectStatus.paid].
bool canCreateAcceleratorPhase(Project project, String? selectedAddress) =>
    selectedAddress != null &&
    project.owner.toString() == selectedAddress &&
    project.status == AcceleratorProjectStatus.active &&
    (project.phases.isEmpty ||
        project.phases.last.status == AcceleratorProjectStatus.paid);

/// Returns whether [selectedAddress] can edit [phase] belonging to [project].
///
/// Requires a non-null [project] owned by [selectedAddress] and [phase] in
/// [AcceleratorProjectStatus.voting].
bool canUpdateAcceleratorPhase({
  required Project? project,
  required Phase phase,
  required String? selectedAddress,
}) =>
    project != null &&
    selectedAddress != null &&
    project.owner.toString() == selectedAddress &&
    phase.status == AcceleratorProjectStatus.voting;
