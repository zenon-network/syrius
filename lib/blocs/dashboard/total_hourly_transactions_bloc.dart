import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class TotalHourlyTransactionsBloc
    extends DashboardBaseBloc<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> makeAsyncCall() async {
    final chainHeight = await _ledgerGetMomentumLedgerHeight();
    if (chainHeight - kMomentumsPerHour > 0) {
      final response =
          (await zenon!.ledger.getDetailedMomentumsByHeight(
                chainHeight - kMomentumsPerHour,
                kMomentumsPerHour,
              ))
                  .list ??
              [];
      return {
        'numAccountBlocks': response.fold<int>(
          0,
          (previousValue, element) => previousValue + element.blocks.length,
        ),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } else {
      throw 'Not enough momentums';
    }
  }

  Future<int> _ledgerGetMomentumLedgerHeight() async {
    try {
      return (await zenon!.ledger.getFrontierMomentum()).height;
    } catch (e) {
      rethrow;
    }
  }
}
