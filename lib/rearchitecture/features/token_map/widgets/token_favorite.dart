import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TokenFavorite extends StatefulWidget {
  const TokenFavorite({
    required this._token,
    required this._callback,
    super.key,
  });
  final Token _token;
  final VoidCallback _callback;

  @override
  State<TokenFavorite> createState() => _TokenFavoriteState();
}

class _TokenFavoriteState extends State<TokenFavorite> {
  final Box _favoriteTokensBox = Hive.box(kFavoriteTokensBox);
  bool _showLoading = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _getToolTipMessage(),
      child: Material(
        shadowColor: Colors.transparent,
        color: Colors.transparent,
        child: _showLoading
            ? const SyriusLoadingWidget(
                size: 15,
              )
            : IconButton(
                padding: EdgeInsets.zero,
                splashRadius: 18,
                onPressed: _onFavoriteIconPressed,
                iconSize: 30,
                icon: Icon(
                  _getFavoriteIcons(),
                  color: _getIconColor(),
                ),
              ),
      ),
    );
  }

  void _onFavoriteIconPressed() {
    return _isTokenInFavorites(widget._token)
        ? _removeTokenFromFavorites()
        : _addTokenToFavorites();
  }

  void _addTokenToFavorites() {
    setState(() {
      _showLoading = true;
    });
    _favoriteTokensBox
        .add(widget._token.tokenStandard.toString())
        .then(
          (int value) async {
            await sl.get<NotificationsBloc>().addNotification(
              WalletNotification(
                title: context.l10n.tokenAddedToFavorites(widget._token.name),
                details: context.l10n.tokenSummary(
                  widget._token.name,
                  widget._token.symbol,
                  widget._token.tokenStandard,
                ),
                timestamp: DateTime.now().millisecondsSinceEpoch,
                type: NotificationType.addedTokenFavourite,
              ),
            );
            setState(() {
              _showLoading = false;
            });
            widget._callback();
          },
          onError: (error) async {
            await NotificationUtils.sendNotificationError(
              error,
              context.l10n.errorAddingTokenToFavorites(widget._token.name),
            );
          },
        );
  }

  Future<void> _removeTokenFromFavorites() async {
    setState(() {
      _showLoading = true;
    });
    await _favoriteTokensBox
        .deleteAt(
          _favoriteTokensBox.values.toList().indexOf(
            widget._token.tokenStandard.toString(),
          ),
        )
        .then(
          (value) async {
            await sl.get<NotificationsBloc>().addNotification(
              WalletNotification(
                title: context.l10n.tokenRemovedFromFavorites(
                  widget._token.name,
                ),
                details: context.l10n.tokenSummary(
                  widget._token.name,
                  widget._token.symbol,
                  widget._token.tokenStandard,
                ),
                timestamp: DateTime.now().millisecondsSinceEpoch,
                type: NotificationType.addedTokenFavourite,
              ),
            );
            setState(() {
              _showLoading = false;
            });
            widget._callback();
          },
          onError: (error) async {
            await NotificationUtils.sendNotificationError(
              error,
              context.l10n.errorRemovingTokenFromFavorites(widget._token.name),
            );
          },
        );
  }

  IconData _getFavoriteIcons() => _isTokenInFavorites(widget._token)
      ? Icons.star_rounded
      : Icons.star_border_rounded;

  bool _isTokenInFavorites(Token token) =>
      _favoriteTokensBox.values.contains(token.tokenStandard.toString());

  String _getToolTipMessage() => _isTokenInFavorites(widget._token)
      ? context.l10n.clickToRemoveFromFavorites
      : context.l10n.clickToAddToFavorites;

  Color _getIconColor() => _isTokenInFavorites(widget._token)
      ? AppColors.znnColor
      : AppColors.lightSecondaryContainer;
}
