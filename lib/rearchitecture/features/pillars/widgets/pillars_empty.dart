import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

/// A widget associated with the [PillarsState] when it's status is
/// [TimerStatus.initial] that uses the [SyriusErrorWidget] to display a
/// message
class PillarsEmpty extends StatelessWidget {
  /// Creates a PillarsEmpty instance
  const PillarsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(context.l10n.waitingForDataFetching);
  }
}
