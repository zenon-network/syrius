import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/p2p_swaps_list_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/native_p2p_swap_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/p2p_swaps_list_item.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class P2pSwapsCard extends StatefulWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;

  const P2pSwapsCard({
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  State<P2pSwapsCard> createState() => _P2pSwapsCardState();
}

class _P2pSwapsCardState extends State<P2pSwapsCard> {
  final ScrollController _scrollController = ScrollController();
  final P2pSwapsListBloc _p2pSwapsListBloc = P2pSwapsListBloc();

  bool _isListScrolled = false;

  @override
  void initState() {
    super.initState();
    _p2pSwapsListBloc.getDataPeriodically();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 0 && !_isListScrolled) {
        setState(() {
          _isListScrolled = true;
        });
      } else if (_scrollController.position.pixels == 0) {
        setState(() {
          _isListScrolled = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _p2pSwapsListBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold<List<P2pSwap>>(
      title: 'P2P Swaps',
      childStream: _p2pSwapsListBloc.stream,
      onCompletedStatusCallback: (data) => data.isEmpty
          ? const SyriusErrorWidget('No P2P swaps')
          : _getTable(data),
      onRefreshPressed: () => _p2pSwapsListBloc.getData(),
      description:
          'This card displays a list of P2P swaps that have been conducted '
          'with this wallet.',
      customItem: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _onDeleteSwapHistoryTapped,
          child: Row(
            children: [
              const Icon(
                Icons.delete,
                color: AppColors.znnColor,
                size: 20.0,
              ),
              const SizedBox(
                width: 5.0,
                height: 38.0,
              ),
              Expanded(
                child: Text(
                  'Delete swap history',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSwapTapped(String swapId) {
    showCustomDialog(
      context: context,
      content: NativeP2pSwapModal(
        swapId: swapId,
      ),
    );
  }

  Future<void> _onDeleteSwapTapped(P2pSwap swap) async {
    showDialogWithNoAndYesOptions(
        context: context,
        isBarrierDismissible: true,
        title: 'Delete swap',
        description:
            'Are you sure you want to delete this swap? This action cannot be undone.',
        onYesButtonPressed: () async {
          if (swap.mode == P2pSwapMode.htlc) {
            await htlcSwapsService!.deleteSwap(swap.id);
          }
          _p2pSwapsListBloc.getData();
        });
  }

  Future<void> _onDeleteSwapHistoryTapped() async {
    showDialogWithNoAndYesOptions(
        context: context,
        isBarrierDismissible: true,
        title: 'Delete swap history',
        description:
            'Are you sure you want to delete your swap history? Active swaps cannot be deleted.',
        onYesButtonPressed: () async {
          await htlcSwapsService!.deleteInactiveSwaps();
          _p2pSwapsListBloc.getData();
        });
  }

  Widget _getTable(List<P2pSwap> swaps) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          _getHeader(),
          const SizedBox(
            height: 15.0,
          ),
          Visibility(
            visible: _isListScrolled,
            child: const Divider(),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: ListView.separated(
                  controller: _scrollController,
                  cacheExtent: 1000,
                  itemCount: swaps.length,
                  separatorBuilder: (_, __) {
                    return const SizedBox(
                      height: 15.0,
                    );
                  },
                  itemBuilder: (_, index) {
                    return P2pSwapsListItem(
                      key: ValueKey(swaps.elementAt(index).id),
                      swap: swaps.elementAt(index),
                      onTap: _onSwapTapped,
                      onDelete: _onDeleteSwapTapped,
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            flex: 20,
            child: _getHeaderItem('Status'),
          ),
          Expanded(
            flex: 20,
            child: _getHeaderItem('From'),
          ),
          Expanded(
            flex: 20,
            child: _getHeaderItem('To'),
          ),
          Expanded(
            flex: 20,
            child: _getHeaderItem('Started'),
          ),
          Expanded(
            flex: 20,
            child: Visibility(
              visible: htlcSwapsService!.isMaxSwapsReached,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _getHeaderItem(
                    'Swap history is full',
                    textColor: AppColors.errorColor,
                    textHeight: 1.0,
                  ),
                  const SizedBox(
                    width: 5.0,
                  ),
                  const Tooltip(
                    message:
                        'The oldest swap entry will be deleted when a new swap is started.',
                    child: Padding(
                      padding: EdgeInsets.only(top: 3.0),
                      child: Icon(
                        Icons.info,
                        color: AppColors.errorColor,
                        size: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getHeaderItem(String text, {Color? textColor, double? textHeight}) {
    return Text(
      text,
      style: TextStyle(fontSize: 12.0, height: textHeight, color: textColor),
    );
  }
}
