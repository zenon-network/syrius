import 'dart:async';

import 'package:expandable/expandable.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/widget_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class CardScaffold<T> extends StatefulWidget {

  const CardScaffold({
    required this.title,
    required this.description,
    this.childBuilder,
    this.childStream,
    this.onRefreshPressed,
    this.onCompletedStatusCallback,
    this.titleFontSize,
    this.titleIcon,
    this.customItem,
    super.key,
  });
  final String? title;
  final String description;
  final Widget Function()? childBuilder;
  final Stream<T>? childStream;
  final VoidCallback? onRefreshPressed;
  final Widget Function(T)? onCompletedStatusCallback;
  final double? titleFontSize;
  final Widget? titleIcon;
  final Widget? customItem;

  @override
  State<CardScaffold<T>> createState() => _CardScaffoldState<T>();
}

class _CardScaffoldState<T> extends State<CardScaffold<T>> {
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  final GlobalKey<LoadingButtonState> _actionButtonKey = GlobalKey();

  final TextEditingController _passwordController = TextEditingController();

  bool? _hideWidgetInfo = false;
  bool _showPasswordInputField = false;

  String? _messageToUser;

  LoadingButton? _actionButton;

  @override
  void initState() {
    super.initState();
    _hideWidgetInfo = _getWidgetHiddenInfoValue(widget.title);
  }

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      flipOnTouch: false,
      key: cardKey,
      onFlipDone: (bool status) {},
      front: ClipRRect(
        borderRadius: BorderRadius.circular(
          15,
        ),
        child: Container(
          color: Theme.of(context).colorScheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _getWidgetHeader(widget.title!),
              const Divider(),
              Expanded(
                child: Material(
                  color: Theme.of(context).colorScheme.primary,
                  child: _getWidgetFrontBody(),
                ),
              ),
            ],
          ),
        ),
      ),
      back: ClipRRect(
        borderRadius: BorderRadius.circular(
          15,
        ),
        child: Material(
          child: Container(
            color: Theme.of(context).colorScheme.primary,
            child: Column(
              children: <Widget>[
                _getWidgetHeader(widget.title!),
                const Divider(),
                Expanded(
                  child: _getHideWidgetInfoViewModel(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getBackBody(HideWidgetStatusBloc model) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          ExpandablePanel(
            collapsed: Container(),
            theme: ExpandableThemeData(
              iconColor: Theme.of(context).textTheme.bodyLarge!.color,
              headerAlignment: ExpandablePanelHeaderAlignment.center,
              iconPlacement: ExpandablePanelIconPlacement.right,
            ),
            header: Row(
              children: <Widget>[
                const Icon(
                  Icons.info,
                  color: AppColors.znnColor,
                  size: 20,
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Text(
                    'Description',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            expanded: Padding(
              padding: const EdgeInsets.only(
                left: 14,
                top: 5,
                bottom: 5,
              ),
              child: Text(
                widget.description,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Row(
            children: <Widget>[
              const Icon(
                Icons.remove_red_eye_rounded,
                color: AppColors.znnColor,
                size: 20,
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child: Text(
                  'Discreet mode',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Spacer(),
              Switch(
                splashRadius: 0,
                value: _hideWidgetInfo!,
                onChanged: (bool value) {
                  setState(() {
                    _hideWidgetInfo = value;
                  });
                  if (value) {
                    if (_getWidgetHiddenInfoValue(widget.title) != value) {
                      model.checkPassAndMarkWidgetWithHiddenValue(
                        widget.title!,
                        _passwordController.text,
                        value,
                      );
                    } else {
                      setState(() {
                        _showPasswordInputField = false;
                      });
                    }
                  } else {
                    setState(() {
                      _showPasswordInputField = true;
                    });
                  }
                },
              ),
            ],
          ),
          Visibility(
            visible: _showPasswordInputField,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _getPasswordInputField(model),
                ),
                const SizedBox(
                  width: 10,
                ),
                _actionButton!,
              ],
            ),
          ),
          if (widget.customItem != null) widget.customItem!,
        ],
      ),
    );
  }

  Widget _getWidgetHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: widget.titleFontSize,
                          height: 1,
                        ),
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                if (widget.titleIcon != null) widget.titleIcon! else Container(),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Visibility(
              visible: widget.onRefreshPressed != null,
              child: Material(
                shadowColor: Colors.transparent,
                color: Colors.transparent,
                child: IconButton(
                  splashRadius: 15,
                  icon: const Icon(Icons.refresh),
                  iconSize: 18,
                  color: Theme.of(context).colorScheme.secondary,
                  onPressed: widget.onRefreshPressed,
                ),
              ),
            ),
            Material(
              shadowColor: Colors.transparent,
              color: Colors.transparent,
              child: IconButton(
                splashRadius: 15,
                icon: const Icon(Icons.more_horiz),
                iconSize: 18,
                color: Theme.of(context).textTheme.bodyLarge!.color,
                onPressed: () {
                  cardKey.currentState!.toggleCard();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getPasswordInputField(HideWidgetStatusBloc model) {
    return PasswordInputField(
      onSubmitted: (String value) {
        _actionButton!.onPressed!();
      },
      controller: _passwordController,
      errorText: _messageToUser,
      hintText: 'Password',
    );
  }

  LoadingButton _getActionButton(HideWidgetStatusBloc model) {
    return LoadingButton.icon(
      onPressed: () => _onActionButtonPressed(model),
      key: _actionButtonKey,
      icon: const Icon(
        AntDesign.arrowright,
        color: AppColors.znnColor,
        size: 25,
      ),
    );
  }

  Widget _getHideWidgetInfoViewModel() {
    return ViewModelBuilder<HideWidgetStatusBloc>.reactive(
      onViewModelReady: (HideWidgetStatusBloc model) {
        _actionButton = _getActionButton(model);
        // Stream will tell us if the widget info is hidden or not
        model.stream.listen(
          (bool? response) {
            if (response != null) {
              _passwordController.clear();
              if (!response) {
                setState(() {
                  _showPasswordInputField = false;
                });
              }
            }
          },
          onError: (error) {
            setState(() {
              _messageToUser = error.toString();
            });
          },
        );
      },
      builder: (_, HideWidgetStatusBloc model, __) => StreamBuilder<bool?>(
        stream: model.stream,
        builder: (_, AsyncSnapshot<bool?> snapshot) {
          if (snapshot.hasError) {
            return _getBackBody(model);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return _getBackBody(model);
            }
            return const Center(
              child: SyriusLoadingWidget(
                size: 25,
              ),
            );
          }
          return _getBackBody(model);
        },
      ),
      viewModelBuilder: HideWidgetStatusBloc.new,
    );
  }

  Widget? _getWidgetFrontBody() {
    return _getWidgetHiddenInfoValue(widget.title)
        ? _getHiddenInfoWidget()
        : widget.childStream != null && widget.onCompletedStatusCallback != null
            ? StreamBuilder<T>(
                stream: widget.childStream,
                builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
                  if (snapshot.hasError) {
                    return SyriusErrorWidget(snapshot.error!);
                  } else if (snapshot.hasData) {
                    return widget
                        .onCompletedStatusCallback!(snapshot.data as T);
                  }
                  return const SyriusLoadingWidget();
                },
              )
            : widget.childBuilder?.call();
  }

  Widget _getHiddenInfoWidget() {
    return Lottie.asset('assets/lottie/ic_anim_eye.json');
  }

  bool _getWidgetHiddenInfoValue(String? title) {
    return sharedPrefsService!.get(
      WidgetUtils.isWidgetHiddenKey(widget.title!),
      defaultValue: false,
    );
  }

  Future<void> _onActionButtonPressed(HideWidgetStatusBloc model) async {
    if (_passwordController.text.isNotEmpty &&
        _actionButtonKey.currentState!.btnState == ButtonState.idle) {
      try {
        _actionButtonKey.currentState!.animateForward();
        await model.checkPassAndMarkWidgetWithHiddenValue(
          widget.title!,
          _passwordController.text,
          _hideWidgetInfo!,
        );
      } catch (_) {
      } finally {
        _actionButtonKey.currentState?.animateReverse();
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
