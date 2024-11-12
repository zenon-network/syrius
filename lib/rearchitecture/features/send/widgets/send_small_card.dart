import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget displayed along with the `Receive` card when the latter has the
/// dimension [CardDimension.large]
///
/// Triggers a callback when it's tapped
class SendSmallCard extends StatefulWidget {
  /// Creates a new instance.
  const SendSmallCard(
    this.onClicked, {
    super.key,
  });
  /// Callback triggered when the widget is tapped
  final VoidCallback onClicked;

  @override
  State<SendSmallCard> createState() => _SendSmallCardState();
}

class _SendSmallCardState extends State<SendSmallCard> {
  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(
          15,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          15,
        ),
        onTap: widget.onClicked,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              SimpleLineIcons.arrow_up_circle,
              size: 60,
              color: AppColors.darkHintTextColor,
            ),
            kVerticalGap16,
            TransferIconLegend(
              legendText: '● ${context.l10n.send}',
            ),
          ],
        ),
      ),
    );
  }
}
