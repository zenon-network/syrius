import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

class RefreshButton extends StatelessWidget {
  /// Constructs a new instance.
  const RefreshButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RefreshButtonCubit, RefreshButtonState>(
      builder: (_, RefreshButtonState state) => switch (state) {
        RefreshCardInitial() => IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<RefreshButtonCubit>().executeRefreshOperation();
            },
          ),
        RefreshCardLoading() => const IconButton(
            onPressed: null,
            icon: SyriusLoadingWidget(
              padding: 0,
              strokeWidth: 2,
              size: 20,
            ),
          ),
      },
    );
  }
}
