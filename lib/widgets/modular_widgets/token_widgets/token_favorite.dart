import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TokenFavorite extends StatefulWidget {

  const TokenFavorite(
    this.token,
    this._tokenFavoritesCallback, {
    super.key,
  });
  final Token token;
  final VoidCallback _tokenFavoritesCallback;

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
    return _isTokenInFavorites(widget.token)
        ? _removeTokenFromFavorites()
        : _addTokenToFavorites();
  }

  void _addTokenToFavorites() {
    setState(() {
      _showLoading = true;
    });
    _favoriteTokensBox.add(widget.token.tokenStandard.toString()).then(
      (value) async {
        await sl.get<NotificationsBloc>().addNotification(
              WalletNotification(
                title: '${widget.token.name} token has been added to favorites',
                details: 'Token ${widget.token.name} with symbol '
                    '${widget.token.name} and ZTS '
                    '${widget.token.tokenStandard}',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                type: NotificationType.addedTokenFavourite,
              ),
            );
        setState(() {
          _showLoading = false;
        });
        widget._tokenFavoritesCallback();
      },
      onError: (error) async {
        await NotificationUtils.sendNotificationError(
          error,
          'Error adding ${widget.token.name} token to favorites',
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
            widget.token.tokenStandard.toString(),
          ),
    )
        .then(
      (value) async {
        await sl.get<NotificationsBloc>().addNotification(
              WalletNotification(
                title: '${widget.token.name} token has been removed '
                    'from favorites',
                details: 'Token ${widget.token.name} with symbol '
                    '${widget.token.name} and ZTS '
                    '${widget.token.tokenStandard}',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                type: NotificationType.addedTokenFavourite,
              ),
            );
        setState(() {
          _showLoading = false;
        });
        widget._tokenFavoritesCallback();
      },
      onError: (error) async {
        await NotificationUtils.sendNotificationError(
          error,
          'Error removing ${widget.token.name} token from favorites',
        );
      },
    );
  }

  IconData _getFavoriteIcons() => _isTokenInFavorites(widget.token)
      ? Icons.star_rounded
      : Icons.star_border_rounded;

  bool _isTokenInFavorites(Token token) =>
      _favoriteTokensBox.values.contains(token.tokenStandard.toString());

  String _getToolTipMessage() => _isTokenInFavorites(widget.token)
      ? 'Click to remove from favorites'
      : 'Click to add to favorites';

  Color _getIconColor() => _isTokenInFavorites(widget.token)
      ? AppColors.znnColor
      : AppColors.lightSecondaryContainer;
}
