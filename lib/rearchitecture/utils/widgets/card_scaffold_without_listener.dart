import 'package:expandable/expandable.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
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
class CardScaffoldWithoutListener extends StatefulWidget {
  /// Creates a [CardScaffoldWithoutListener] instance.
  const CardScaffoldWithoutListener({
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
  State<CardScaffoldWithoutListener> createState() =>
      _CardScaffoldWithoutListenerState();
}

class _CardScaffoldWithoutListenerState
    extends State<CardScaffoldWithoutListener> {
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  final GlobalKey<LoadingButtonState> _actionButtonKey = GlobalKey();

  final TextEditingController _passwordController = TextEditingController();

  bool _hideWidgetInfo = false;
  bool _showPasswordInputField = false;

  String? _messageToUser;

  late LoadingButton _actionButton;

  String get _title => widget.data.title;

  String get _description => widget.data.description;

  @override
  void initState() {
    super.initState();
    _hideWidgetInfo = _getWidgetHiddenInfoValue(_title);
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
        child: ColoredBox(
          color: Theme.of(context).colorScheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _getWidgetHeader(_title),
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
          child: ColoredBox(
            color: Theme.of(context).colorScheme.primary,
            child: Column(
              children: <Widget>[
                _getWidgetHeader(_title),
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
                kHorizontalGap4,
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
                _description,
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
              kHorizontalGap4,
              Expanded(
                child: Text(
                  'Discreet mode',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Spacer(),
              Switch(
                splashRadius: 0,
                value: _hideWidgetInfo,
                onChanged: (bool value) {
                  setState(() {
                    _hideWidgetInfo = value;
                  });
                  if (value) {
                    if (_getWidgetHiddenInfoValue(_title) != value) {
                      model.checkPassAndMarkWidgetWithHiddenValue(
                        _title,
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
                kHorizontalGap8,
                _actionButton,
              ],
            ),
          ),
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                kHorizontalGap4,
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
        _actionButton.onPressed!();
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
          onError: (dynamic error) {
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
    return _getWidgetHiddenInfoValue(_title)
        ? _getHiddenInfoWidget()
        : widget.body;
  }

  Widget _getHiddenInfoWidget() {
    return Lottie.asset('assets/lottie/ic_anim_eye.json');
  }

  bool _getWidgetHiddenInfoValue(String? title) {
    return sharedPrefsService!.get(
      WidgetUtils.isWidgetHiddenKey(_title),
      defaultValue: false,
    );
  }

  Future<void> _onActionButtonPressed(HideWidgetStatusBloc model) async {
    if (_passwordController.text.isNotEmpty &&
        _actionButtonKey.currentState!.btnState == ButtonState.idle) {
      try {
        _actionButtonKey.currentState!.animateForward();
        await model.checkPassAndMarkWidgetWithHiddenValue(
          _title,
          _passwordController.text,
          _hideWidgetInfo,
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
