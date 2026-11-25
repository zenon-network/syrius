import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays localized metadata (owner, ID, creation date, voting countdown)
/// for an Accelerator project or phase.
class AcceleratorProjectMetadata extends StatelessWidget {
  /// Creates an [AcceleratorProjectMetadata].
  const AcceleratorProjectMetadata({
    this._owner,
    this._hash,
    this._creationTimestamp,
    this._acceleratorProjectStatus,
    this._isPhase = false,
    this._nowProvider,
    super.key,
  });

  final Address? _owner;
  final Hash? _hash;
  final int? _creationTimestamp;
  final AcceleratorProjectStatus? _acceleratorProjectStatus;
  final bool _isPhase;
  final DateTime Function()? _nowProvider;

  @override
  Widget build(BuildContext context) {
    final TextStyle? hintStyle = Theme.of(
      context,
    ).inputDecorationTheme.hintStyle;
    final List<Widget> children = <Widget>[];

    if (_owner != null) {
      children.add(
        Text(_formatOwnerDetails(context, _owner), style: hintStyle),
      );
    }

    if (_hash != null) {
      children.add(
        Text(context.l10n.idWithValue(_hash.toShortString()), style: hintStyle),
      );
    }

    if (_creationTimestamp != null) {
      children.add(
        Text(
          context.l10n.createdWithDate(
            _formatCreationDate(context, _creationTimestamp * 1000),
          ),
          style: hintStyle,
        ),
      );
      if (!_isPhase &&
          _acceleratorProjectStatus == AcceleratorProjectStatus.voting) {
        children.add(
          Text(
            _formatTimeUntilVotingCloses(context, _creationTimestamp),
            style: hintStyle,
          ),
        );
      }
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children.zip(
        List<Widget>.generate(
          children.length - 1,
          (int index) => Text(' ● ', style: hintStyle),
        ),
      ),
    );
  }

  String _formatCreationDate(BuildContext context, int transactionMillis) {
    final DateTime now = (_nowProvider ?? DateTime.now)();
    final int currentMillis = now.millisecondsSinceEpoch;
    final int elapsedMillis = currentMillis - transactionMillis;
    if (elapsedMillis >= 0 &&
        elapsedMillis <= const Duration(days: 1).inMilliseconds) {
      return _formatShortElapsed(context, elapsedMillis);
    }
    return FormatUtils.formatDate(
      transactionMillis,
      dateFormat: context.l10n.usDateFormat,
    );
  }

  String _formatShortElapsed(BuildContext context, int elapsedMillis) {
    final Duration duration = Duration(milliseconds: elapsedMillis);
    if (duration.inHours > 0) {
      return '${duration.inHours} ${context.l10n.hAgo}';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${context.l10n.minAgo}';
    }
    return '${duration.inSeconds} ${context.l10n.sAgo}';
  }

  String _formatTimeUntilVotingCloses(
    BuildContext context,
    int creationTimestamp,
  ) {
    final DateTime now = (_nowProvider ?? DateTime.now)();
    final DateTime creationDate = DateTime.fromMillisecondsSinceEpoch(
      creationTimestamp * 1000,
    );
    final DateTime votingEnds = creationDate.add(kProjectVotingPeriod);
    final Duration difference = votingEnds.difference(now);
    if (difference.isNegative) {
      return context.l10n.votingClosed;
    }
    final String suffix;
    if (difference.inDays > 0) {
      suffix = context.l10n.daysCount(difference.inDays);
    } else if (difference.inHours > 0) {
      suffix = context.l10n.hoursCount(difference.inHours);
    } else if (difference.inMinutes > 0) {
      suffix = context.l10n.minutesCount(difference.inMinutes);
    } else {
      suffix = context.l10n.secondsCount(difference.inSeconds);
    }
    return context.l10n.votingClosesIn(suffix);
  }

  String _formatOwnerDetails(BuildContext context, Address owner) {
    final String ownerStr = owner.toString();
    final String display = kDefaultAddressList.contains(ownerStr)
        ? (kAddressLabelMap[ownerStr] ?? owner.toShortString())
        : owner.toShortString();
    return context.l10n.ownerWithAddress(display);
  }
}
