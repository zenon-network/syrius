import 'package:expandable/expandable.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/new_app_themes.dart';
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
  State<NewCardScaffold> createState() =>
      _NewCardScaffoldState();
}

class _NewCardScaffoldState
    extends State<NewCardScaffold> {
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  final GlobalKey<LoadingButtonState> _actionButtonKey = GlobalKey();

  final TextEditingController _passwordController = TextEditingController();

  late bool _shouldHideWidgetInfo;
  bool _showPasswordInputField = false;

  String? _messageToUser;

  late LoadingButton _actionButton;

  String get _title => widget.data.title;

  String get _description => widget.data.description;

  final ValueNotifier<bool> _obscureTextNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _shouldHideWidgetInfo = _isWidgetInfoHidden(_title);
  }

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
        _isWidgetInfoHidden(_title) ? _getHiddenInfoWidget() : widget.body;

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final ThemeData themeData = isDarkMode ? newDarkTheme : newLightTheme;

    final Color background = isDarkMode ? AppColors.darkPrimary : Colors.white;

    return Theme(
      data: themeData,
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

  Widget _getBackBody(HideWidgetStatusBloc model) {
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
                  iconColor: Theme.of(context).iconTheme.color,
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
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                expanded: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _description,
                    style: Theme.of(context).textTheme.bodyMedium,
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
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _shouldHideWidgetInfo,
                    onChanged: (bool value) {
                      setState(() {
                        _shouldHideWidgetInfo = value;
                      });
                      if (value) {
                        if (_isWidgetInfoHidden(_title) != value) {
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
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _obscureTextNotifier,
                        builder: (_, bool obscureText, __) {
                          return CardScaffoldPasswordField(
                            controller: _passwordController,
                            errorText: _messageToUser,
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
    return ViewModelBuilder<HideWidgetStatusBloc>.reactive(
      onViewModelReady: (HideWidgetStatusBloc model) {
        _actionButton = LoadingButton.icon(
          onPressed: () => _onActionButtonPressed(model),
          key: _actionButtonKey,
          icon: const Icon(
            AntDesign.arrowright,
            color: AppColors.znnColor,
            size: 25,
          ),
        );
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

  Widget _getHiddenInfoWidget() {
    return Lottie.asset('assets/lottie/ic_anim_eye.json');
  }

  bool _isWidgetInfoHidden(String title) {
    return sharedPrefsService!.get(
      WidgetUtils.isWidgetHiddenKey(title),
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
          _shouldHideWidgetInfo,
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
