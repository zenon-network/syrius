import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

/// A widget associated with the [ActivePillarsState] when it's status is
/// [TimerStatus.failure] that uses the [SyriusErrorWidget] to display the
/// error message.
class ActivePillarsError extends StatelessWidget {
  /// Creates a PillarsError object.
  const ActivePillarsError({required this.error, super.key});

  /// Holds the data that will be displayed.
  final SyriusException error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}
