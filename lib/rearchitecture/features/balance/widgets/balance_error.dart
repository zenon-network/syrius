import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/balance/balance.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';

/// A [BalanceError] widget that displays an error message when the balance
/// data fetching fails.
///
/// This widget is displayed when the [BalanceCubit] encounters an error
/// while trying to load the balance data.
class BalanceError extends StatelessWidget {
  /// Creates a BalanceError object.
  const BalanceError({required this.error, super.key});

  /// The object used to display an error message.
  final SyriusException error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}
