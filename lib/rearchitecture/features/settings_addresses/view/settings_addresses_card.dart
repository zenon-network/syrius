import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:number_selector/number_selector.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays wallet addresses, default address selection, label editing,
/// and generation of additional wallet addresses.
class SettingsAddressesCard extends StatelessWidget {
  /// Creates a [SettingsAddressesCard].
  const SettingsAddressesCard({super.key, this._bloc});

  final SettingsAddressesBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    final SettingsAddressesBloc? injected = _bloc;
    if (injected != null) {
      return BlocProvider<SettingsAddressesBloc>.value(
        value: injected,
        child: const _View(),
      );
    }

    return BlocProvider<SettingsAddressesBloc>(
      create: (_) => SettingsAddressesBloc(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      body: MultiBlocListener(
        listeners:
            <BlocListener<SettingsAddressesBloc, SettingsAddressesState>>[
              BlocListener<SettingsAddressesBloc, SettingsAddressesState>(
                listenWhen:
                    (
                      SettingsAddressesState previous,
                      SettingsAddressesState current,
                    ) =>
                        previous.defaultAddressChangeNonce !=
                        current.defaultAddressChangeNonce,
                listener: _onDefaultAddressChanged,
              ),
              BlocListener<SettingsAddressesBloc, SettingsAddressesState>(
                listenWhen:
                    (
                      SettingsAddressesState previous,
                      SettingsAddressesState current,
                    ) => previous.scrollToEndNonce != current.scrollToEndNonce,
                listener: (_, _) => _scrollToBottom(),
              ),
              BlocListener<SettingsAddressesBloc, SettingsAddressesState>(
                listenWhen:
                    (
                      SettingsAddressesState previous,
                      SettingsAddressesState current,
                    ) =>
                        previous.labelUpdateNonce != current.labelUpdateNonce &&
                        current.labelError != null,
                listener: _onLabelError,
              ),
            ],
        child: BlocBuilder<SettingsAddressesBloc, SettingsAddressesState>(
          builder: (BuildContext context, SettingsAddressesState state) {
            return switch (state.status) {
              SettingsAddressesStatus.loading => const SyriusLoadingWidget(),
              SettingsAddressesStatus.failure => SyriusErrorWidget(
                state.error ?? context.l10n.somethingWentWrong,
              ),
              SettingsAddressesStatus.ready => _Populated(
                state: state,
                scrollController: _scrollController,
              ),
            };
          },
        ),
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.addresses,
    description: context.l10n.selectDefaultAddressForOperations,
  );

  void _onDefaultAddressChanged(
    BuildContext context,
    SettingsAddressesState state,
  ) {
    final String? newDefaultAddress = state.selectedAddress;
    if (newDefaultAddress == null) {
      return;
    }

    Provider.of<SelectedAddressNotifier>(
      context,
      listen: false,
    ).changeSelectedAddress(newDefaultAddress);

    context.read<PlasmaBeneficiaryAddressCubit>().changeAddress(
      newDefaultAddress,
    );

    final Address parsedAddress = Address.parse(newDefaultAddress);
    context.read<AccountChainStatsBloc>().add(
      FetchRequestData(address: parsedAddress),
    );
    context.read<LatestTransactionsBloc>().add(
      InfiniteListRefreshRequested(address: parsedAddress),
    );
    context.read<PendingTransactionsBloc>().add(
      InfiniteListRefreshRequested(address: parsedAddress),
    );
    context.read<PillarRewardsHistoryBloc>().add(
      FetchRequestData(address: parsedAddress),
    );
    context.read<SentinelRewardsHistoryBloc>().add(
      FetchRequestData(address: parsedAddress),
    );
    context.read<StakingRewardsHistoryBloc>().add(
      FetchRequestData(address: parsedAddress),
    );
    context.read<PillarsByOwnerBloc>().add(
      FetchRequestData(address: parsedAddress),
    );
    context.read<DelegationStatsBloc>().add(
      FetchRequestData(address: parsedAddress),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _onLabelError(BuildContext context, SettingsAddressesState state) {
    final SettingsAddressLabelError? labelError = state.labelError;
    if (labelError == null) {
      return;
    }
    final String failedLabel = state.failedLabel ?? '';
    switch (labelError) {
      case SettingsAddressLabelError.empty:
        unawaited(
          NotificationUtils.sendNotificationError(
            context.l10n.labelCannotBeEmpty,
            context.l10n.labelCannotBeEmpty,
          ),
        );
      case SettingsAddressLabelError.tooLong:
        unawaited(
          NotificationUtils.sendNotificationError(
            context.l10n.labelExceedsMaxLength(
              failedLabel,
              failedLabel.length,
              kAddressLabelMaxLength,
            ),
            context.l10n.labelHasTooManyCharacters(kAddressLabelMaxLength),
          ),
        );
      case SettingsAddressLabelError.alreadyExists:
        unawaited(
          NotificationUtils.sendNotificationError(
            context.l10n.labelAlreadyExistsInDatabase(failedLabel),
            context.l10n.labelAlreadyExists,
          ),
        );
      case SettingsAddressLabelError.unexpected:
        unawaited(
          NotificationUtils.sendNotificationError(
            state.labelErrorCause ?? context.l10n.somethingWentWrong,
            context.l10n.errorChangingAddressLabel,
          ),
        );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _Populated extends StatelessWidget {
  const _Populated({required this._state, required this._scrollController});

  final SettingsAddressesState _state;
  final ScrollController _scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: _buildAddressList(context)),
        const Divider(),
        _buildAddAddressRow(context),
      ],
    );
  }

  Widget _buildAddressList(BuildContext context) {
    final SettingsAddressesBloc bloc = context.read<SettingsAddressesBloc>();
    return Scrollbar(
      controller: _scrollController,
      child: RadioGroup<String>(
        groupValue: _state.selectedAddress,
        onChanged: (String? value) {
          if (value != null) {
            bloc.add(SettingsAddressesDefaultChanged(address: value));
          }
        },
        child: ListView.builder(
          controller: _scrollController,
          key: const PageStorageKey<String>('Addresses list view'),
          shrinkWrap: true,
          itemCount: _state.addresses.length,
          itemBuilder: (BuildContext context, int index) {
            final String address = _state.addresses[index];
            final String label =
                _state.addressLabels[address] ??
                context.l10n.defaultAddressLabel(index + 1);
            return Row(
              children: <Widget>[
                Radio<String>(value: address),
                Expanded(
                  child: SettingsAddressTile(
                    key: ValueKey<String>(address),
                    address: address,
                    label: label,
                    isSavingLabel: _state.updatingLabelAddress == address,
                    onAddressPressed: (String selected) {
                      bloc.add(
                        SettingsAddressesDefaultChanged(address: selected),
                      );
                    },
                    onLabelSubmitted: (String newLabel) {
                      bloc.add(
                        SettingsAddressesLabelUpdated(
                          address: address,
                          label: newLabel,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddAddressRow(BuildContext context) {
    final SettingsAddressesBloc bloc = context.read<SettingsAddressesBloc>();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NumberSelector.plain(
                borderColor: AppColors.znnColor,
                iconColor: AppColors.znnColor,
                dividerColor: AppColors.znnColor,
                current: _state.numberOfAddressesToAdd,
                min: 1,
                max: 10,
                onUpdate: (int val) {
                  bloc.add(SettingsAddressesCountChanged(count: val));
                },
              ),
            ),
          ),
          InkWell(
            onTap: () {
              bloc.add(
                SettingsAddressesGenerateRequested(
                  count: _state.numberOfAddressesToAdd,
                ),
              );
            },
            child: Container(
              constraints: const BoxConstraints(minWidth: 150, minHeight: 50),
              alignment: Alignment.center,
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.add_circle,
                    color: AppColors.znnColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.addAddressesCount(
                      _state.numberOfAddressesToAdd,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
