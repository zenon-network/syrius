import 'package:zenon_syrius_wallet_flutter/utils/card/card_data.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';

enum CardType {
  delegationStats;

  CardData get data {
    return switch (this) {
      CardType.delegationStats => CardData(
          title: 'Delegation Stats',
          description: 'This card displays the amount of ${kZnnCoin.symbol} '
              'and the name of the Pillar that you delegated to',
        ),
    };
  }
}
