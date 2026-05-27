part of 'infinite_scroll_table.dart';

// ignore_for_file: public_member_api_docs
enum InfiniteScrollTableColumnType {
  amount,
  asset,
  blank,
  date,
  delegation,
  delegationReward,
  expectedProducedMomentums,
  hash,
  momentumReward,
  pillarName,
  producerAddress,
  receiver,
  sender,
  type,
  uptime,
  weight;

  int get flex => switch (this) {
    amount => 1,
    asset => 1,
    blank => 1,
    date => 1,
    delegation => 1,
    delegationReward => 1,
    expectedProducedMomentums => 1,
    hash => 2,
    momentumReward => 1,
    pillarName => 1,
    producerAddress => 3,
    receiver => 2,
    sender => 2,
    type => 1,
    uptime => 1,
    weight => 1,
  };

  String name({required BuildContext context}) => switch (this) {
    amount => context.l10n.amount,
    asset => context.l10n.asset,
    blank => '',
    date => context.l10n.date,
    delegation => context.l10n.delegation,
    delegationReward => context.l10n.delegationReward,
    expectedProducedMomentums => context.l10n.expectedProducedMomentums,
    hash => context.l10n.hash,
    momentumReward => context.l10n.momentumReward,
    pillarName => context.l10n.name,
    producerAddress => context.l10n.producerAddress,
    receiver => context.l10n.receiver,
    sender => context.l10n.sender,
    type => context.l10n.type,
    uptime => context.l10n.uptime,
    weight => context.l10n.weight,
  };

  MainAxisAlignment get aligment => switch (this) {
    delegation => MainAxisAlignment.center,
    _ => MainAxisAlignment.start,
  };
}
