import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AcceleratorProjectDetails extends StatelessWidget {
  final Address? owner;
  final Hash? hash;
  final int? creationTimestamp;
  final AcceleratorProjectStatus? acceleratorProjectStatus;
  final bool isPhase;

  const AcceleratorProjectDetails({
    this.owner,
    this.hash,
    this.creationTimestamp,
    this.acceleratorProjectStatus,
    this.isPhase = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    if (owner != null) {
      children.add(Text(
        _getOwnerDetails(),
        style: Theme.of(context).inputDecorationTheme.hintStyle,
      ));
    }

    if (hash != null) {
      children.add(
        Text(
          'ID ${hash!.toShortString()}',
          style: Theme.of(context).inputDecorationTheme.hintStyle,
        ),
      );
    }

    if (creationTimestamp != null) {
      children.add(Text(
        'Created ${_formatData(creationTimestamp! * 1000)}',
        style: Theme.of(context).inputDecorationTheme.hintStyle,
      ));
      if (!isPhase &&
          acceleratorProjectStatus != null &&
          acceleratorProjectStatus == AcceleratorProjectStatus.voting) {
        children.add(Text(
          _getTimeUntilVotingCloses(),
          style: Theme.of(context).inputDecorationTheme.hintStyle,
        ));
      }
    }

    return Row(
      children: children.zip(List.generate(
        children.length - 1,
        (index) => Text(
          ' ● ',
          style: Theme.of(context).inputDecorationTheme.hintStyle,
        ),
      )),
    );
  }

  String _formatData(int transactionMillis) {
    int currentMillis = DateTime.now().millisecondsSinceEpoch;
    if (currentMillis - transactionMillis <=
        const Duration(
          days: 1,
          minutes: 0,
          seconds: 0,
          milliseconds: 0,
        ).inMilliseconds) {
      return _formatDataShort(currentMillis - transactionMillis);
    }
    return FormatUtils.formatDate(transactionMillis, dateFormat: 'MM/dd/yyyy');
  }

  String _formatDataShort(int i) {
    Duration duration = Duration(milliseconds: i);
    if (duration.inHours > 0) {
      return '${duration.inHours} h ago';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min ago';
    }
    return '${duration.inSeconds} s ago';
  }

  String _getTimeUntilVotingCloses() {
    String prefix = 'Voting closes in ';
    String suffix = '';
    DateTime creationDate =
        DateTime.fromMillisecondsSinceEpoch((creationTimestamp ?? 0) * 1000);
    DateTime votingEnds = creationDate.add(kProjectVotingPeriod);
    Duration difference = votingEnds.difference(DateTime.now());
    if (difference.isNegative) {
      return 'Voting closed';
    }
    if (difference.inDays > 0) {
      suffix = '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      suffix = '${difference.inHours} h';
    } else if (difference.inMinutes > 0) {
      suffix = '${difference.inMinutes} min';
    } else {
      suffix = '${difference.inSeconds} s';
    }
    return prefix + suffix;
  }

  String _getOwnerDetails() {
    String address = owner!.toShortString();
    if (kDefaultAddressList.contains(owner.toString())) {
      address = kAddressLabelMap[owner.toString()]!;
    }
    return 'Owner $address';
  }
}
