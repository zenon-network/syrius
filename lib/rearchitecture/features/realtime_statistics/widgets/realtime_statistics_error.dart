import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

/// A widget that displays an error message
class RealtimeStatisticsError extends StatelessWidget {
  /// Creates a RealtimeStatisticsError object
  const RealtimeStatisticsError({required this.error, super.key});

  /// The data that holds the message that will be displayed
  final SyriusException error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}
