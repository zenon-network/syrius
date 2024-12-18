part of 'infinite_scroll_table.dart';

// ignore_for_file: public_member_api_docs
enum InfiniteScrollTableColumnType {
  amount,
  asset,
  blank,
  date,
  hash,
  receiver,
  sender,
  type;

  int get flex => switch (this) {
        amount => 1,
        asset => 1,
        blank => 1,
        date => 1,
        hash => 2,
        receiver => 2,
        sender => 2,
        type => 1,
      };

  String name({required BuildContext context}) => switch (this) {
        amount => context.l10n.amount,
        asset => context.l10n.asset,
        blank => '',
        date => context.l10n.date,
        hash => context.l10n.hash,
        receiver => context.l10n.receiver,
        sender => context.l10n.sender,
        type => context.l10n.type,
      };
}
