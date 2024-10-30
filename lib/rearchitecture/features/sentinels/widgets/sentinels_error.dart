import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget associated with the [SentinelsState] when it's status is
/// [TimerStatus.failure] that uses the [SyriusErrorWidget] to display an
/// error.
class SentinelsError extends StatelessWidget {
  /// Creates a SentinelsError objects.
  const SentinelsError({required this.error, super.key});

  /// The object that holds the representation of the error
  final SyriusException error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}
