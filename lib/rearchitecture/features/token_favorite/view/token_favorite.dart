import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/token_favorite/bloc/token_favorite_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TokenFavorite extends StatelessWidget {
  const TokenFavorite({
    required this._token,
    required this._callback,
    super.key,
  });
  final Token _token;
  final VoidCallback _callback;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TokenFavoriteBloc>(
      create: (_) => TokenFavoriteBloc(
        tokenStandard: _token.tokenStandard,
      ),
      child: _View(callback: _callback, token: _token),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this._callback, required this._token});

  final VoidCallback _callback;
  final Token _token;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TokenFavoriteBloc, TokenFavoriteState>(
      listener: _onTokenFavoriteStateChanged,
      builder: (BuildContext context, TokenFavoriteState state) =>
          switch (state) {
            TokenFavoriteLoading() => const SyriusLoadingWidget(size: 15),
            TokenFavoriteAddSuccess() => _buildRemoveButton(context),
            TokenFavoriteRemoveSuccess() => _buildAddButton(context),
            TokenFavoriteAddFailure() => _buildAddButton(context),
            TokenFavoriteRemoveFailure() => _buildRemoveButton(context),
          },
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Tooltip(
      message: context.l10n.clickToAddToFavorites,
      child: IconButton(
        onPressed: () => context.read<TokenFavoriteBloc>().add(
          const TokenFavoriteAdded(),
        ),
        icon: const Icon(
          Icons.star_border,
          color: AppColors.lightSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context) {
    return Tooltip(
      message: context.l10n.clickToRemoveFromFavorites,
      child: IconButton(
        onPressed: () => context.read<TokenFavoriteBloc>().add(
          const TokenFavoriteRemoved(),
        ),
        icon: const Icon(Icons.star, color: AppColors.znnColor),
      ),
    );
  }

  void _onTokenFavoriteStateChanged(
    BuildContext context,
    TokenFavoriteState state,
  ) {
    if (state is TokenFavoriteAddSuccess) {
      unawaited(_sendAddedNotification(context));
    } else if (state is TokenFavoriteRemoveSuccess) {
      unawaited(_sendRemovedNotification(context));
    } else if (state is TokenFavoriteAddFailure) {
      unawaited(
        NotificationUtils.sendNotificationError(
          state.error,
          context.l10n.errorAddingTokenToFavorites(_token.name),
        ),
      );
    } else if (state is TokenFavoriteRemoveFailure) {
      unawaited(
        NotificationUtils.sendNotificationError(
          state.error,
          context.l10n.errorRemovingTokenFromFavorites(_token.name),
        ),
      );
    }
  }

  Future<void> _sendAddedNotification(BuildContext context) async {
    await sl.get<NotificationsBloc>().addNotification(
      WalletNotification(
        title: context.l10n.tokenAddedToFavorites(_token.name),
        details: context.l10n.tokenSummary(
          _token.name,
          _token.symbol,
          _token.tokenStandard,
        ),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: NotificationType.addedTokenFavourite,
      ),
    );
    _callback();
  }

  Future<void> _sendRemovedNotification(BuildContext context) async {
    await sl.get<NotificationsBloc>().addNotification(
      WalletNotification(
        title: context.l10n.tokenRemovedFromFavorites(_token.name),
        details: context.l10n.tokenSummary(
          _token.name,
          _token.symbol,
          _token.tokenStandard,
        ),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: NotificationType.addedTokenFavourite,
      ),
    );
    _callback();
  }
}
