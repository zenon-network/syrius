import 'dart:async';

import 'package:expandable/expandable.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/card_scaffold_header.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/card_scaffold_password_field.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A scaffold for the standard card used across the app
///
/// It comes with a lot of predefined styling and features
///
/// On the front, it display a title, contained by [data], a [body], the main
/// front widget, an [IconButton] to flip the card and, if [onRefreshPressed]
/// is not null, an [IconButton] to trigger a callback
/// On the back, it display a description, contained by [data], a [Switch] to
/// hide the [body] and - if the widget is already hidden - an
/// [PasswordInputField] to input the wallet password and make the [body]
/// visible again
class NewCardScaffold extends StatefulWidget {
  /// Creates a [NewCardScaffold] instance.
  const NewCardScaffold({
    required this.body,
    required this.data,
    this.onRefreshPressed,
    super.key,
  });

  /// Widget that will appear on the front of the card
  final Widget body;

  /// Data needed for certain UI parts of the card
  final CardData data;

  /// Optional callback that can be trigger from the card
  final VoidCallback? onRefreshPressed;

  @override
  State<NewCardScaffold> createState() => _NewCardScaffoldState();
}

class _NewCardScaffoldState extends State<NewCardScaffold> {
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  final GlobalKey<LoadingButtonState> _actionButtonKey = GlobalKey();

  final TextEditingController _passwordController = TextEditingController();

  bool _showPasswordInputField = false;

  SyriusException? _error;

  late LoadingButton _actionButton;

  String get _title => widget.data.title;

  String get _description => widget.data.description;

  final ValueNotifier<bool> _obscureTextNotifier = ValueNotifier<bool>(true);

  @override
  Widget build(BuildContext context) {
    final Widget card = CardScaffoldHeader(
      onMoreIconPressed: () {
        cardKey.currentState!.toggleCard();
      },
      onRefreshPressed: widget.onRefreshPressed,
      title: _title,
    );

    final Widget front =
        _isFrontWidgetHidden(_title) ? _getHiddenInfoWidget() : widget.body;

    final Color background =
        context.isDarkMode ? AppColors.darkPrimary : Colors.white;

    return Theme(
      data: context.newTheme,
      child: Builder(
        builder: (BuildContext context) {
          return FlipCard(
            flipOnTouch: false,
            key: cardKey,
            onFlipDone: (bool status) {},
            front: ClipRRect(
              borderRadius: BorderRadius.circular(
                15,
              ),
              child: ColoredBox(
                color: background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    card,
                    const Divider(),
                    Expanded(
                      child: front,
                    ),
                  ],
                ),
              ),
            ),
            back: ClipRRect(
              borderRadius: BorderRadius.circular(
                15,
              ),
              child: ColoredBox(
                color: background,
                child: Column(
                  children: <Widget>[
                    card,
                    const Divider(),
                    Expanded(
                      child: _getHideWidgetInfoViewModel(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getBackBody() {
    return Builder(
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              ExpandablePanel(
                collapsed: const SizedBox.shrink(),
                theme: ExpandableThemeData(
                  iconColor: context.newTheme.iconTheme.color,
                  iconPlacement: ExpandablePanelIconPlacement.right,
                  headerAlignment: ExpandablePanelHeaderAlignment.center,
                ),
                header: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.info,
                      color: AppColors.znnColor,
                    ),
                    kHorizontalGap4,
                    Expanded(
                      child: Text(
                        'Description',
                        style: context.newTheme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                expanded: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _description,
                    style: context.newTheme.textTheme.bodyMedium,
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.remove_red_eye_rounded,
                    color: AppColors.znnColor,
                  ),
                  kHorizontalGap4,
                  Expanded(
                    child: Text(
                      'Discreet mode',
                      style: context.newTheme.textTheme.titleSmall,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isFrontWidgetHidden(_title),
                    onChanged: (bool shouldHideFrontWidget) {
                      if (shouldHideFrontWidget) {
                        context.read<HideWidgetCubit>().saveValue(
                              isHidden: shouldHideFrontWidget,
                              widgetTitle: _title,
                            );
                      } else {
                        // To make the front widget visible, the user needs to
                        // confirm with it's wallet password
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
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _obscureTextNotifier,
                        builder: (_, bool obscureText, __) {
                          return CardScaffoldPasswordField(
                            controller: _passwordController,
                            errorText: _error?.toString(),
                            onSubmitted: (String value) {
                              _actionButton.onPressed!();
                            },
                            obscureText: obscureText,
                            onSuffixIconPressed: () {
                              _obscureTextNotifier.value = !obscureText;
                            },
                          );
                        },
                      ),
                    ),
                    kHorizontalGap8,
                    _actionButton,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getHideWidgetInfoViewModel() {
    return BlocProvider<HideWidgetCubit>(
      create: (_) {
        final HideWidgetCubit cubit = HideWidgetCubit();

        _actionButton = LoadingButton.icon(
          onPressed: () => _onActionButtonPressed(cubit: cubit),
          key: _actionButtonKey,
          icon: const Icon(
            AntDesign.arrowright,
            color: AppColors.znnColor,
            size: 25,
          ),
        );

        return cubit;
      },
      child: BlocListener<HideWidgetCubit, HideWidgetState>(
        listener: (BuildContext context, HideWidgetState state) {
          final HideWidgetStatus status = state.status;
          switch (status) {
            case HideWidgetStatus.failure:
              _actionButtonKey.currentState?.animateReverse();
              setState(() {
                _error = state.exception;
              });
            case HideWidgetStatus.initial:
              break;
            case HideWidgetStatus.loading:
              _actionButtonKey.currentState?.animateForward();
            case HideWidgetStatus.success:
              _actionButtonKey.currentState?.animateReverse();
              _passwordController.clear();
              if (!state.isHidden!) {
                _showPasswordInputField = false;
              }
              _error = null;
              setState(() {});
          }
        },
        child: _getBackBody(),
      ),
    );
  }

  Widget _getHiddenInfoWidget() {
    return Lottie.asset('assets/lottie/ic_anim_eye.json');
  }

  bool _isFrontWidgetHidden(String title) {
    return sharedPrefsService!.get(
      WidgetUtils.isWidgetHiddenKey(title),
      defaultValue: false,
    );
  }

  Future<void> _onActionButtonPressed({required HideWidgetCubit cubit}) async {
    if (_passwordController.text.isNotEmpty &&
        _actionButtonKey.currentState!.btnState == ButtonState.idle) {
      unawaited(
        cubit.saveValue(
          isHidden: false,
          password: _passwordController.text,
          widgetTitle: _title,
        ),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
