import 'dart:math';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/screens/onboarding/new_wallet/new_wallet_password_screen.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/onboarding_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/standard_tooltip_icon.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/progress_bars.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/seed/seed_grid.dart';

class NewWalletConfirmSeedScreen extends StatefulWidget {
  final List<String> seedWords;

  const NewWalletConfirmSeedScreen(
    this.seedWords, {
    Key? key,
  }) : super(key: key);

  @override
  _NewWalletConfirmSeedScreenState createState() =>
      _NewWalletConfirmSeedScreenState();
}

class _NewWalletConfirmSeedScreenState
    extends State<NewWalletConfirmSeedScreen> {
  bool _seedError = false;
  int? _hoveredSeedGridIndex;
  int? _textCursor;

  late Widget _actionButton;
  String? _draggedValue;

  final List<SeedGridElement> _seedGridElements = [];
  final List<int> _randomIndexes = [];
  List<int> _foundMissingRandomElementsIndexes = [];

  @override
  void initState() {
    super.initState();
    _actionButton = _getVerifyButton();
    for (var word in widget.seedWords) {
      _seedGridElements.add(
        SeedGridElement(
          word: word,
          isValid: true,
          isShown: true,
        ),
      );
    }
    _generateRandomIndexes();
    for (var index in _randomIndexes) {
      _seedGridElements[index].word = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: [
                const ProgressBar(
                  currentLevel: 2,
                ),
                const SizedBox(
                  height: 30.0,
                ),
                Text(
                  'Confirm your seed',
                  style: Theme.of(context).textTheme.headline1,
                ),
                kVerticalSpacing,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Drag & drop the words in the correct order',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                    const StandardTooltipIcon(
                      'You can drag & drop words on empty boxes or incorrect words',
                      Icons.help,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 75.0,
                ),
                _getSeedInputWidgetsGrid(),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 90.0),
                  child: _getMissingSeedGridElements(widget.seedWords),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _getPassiveButton(),
                kSpacingBetweenActionButtons,
                _actionButton,
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generateRandomIndexes() {
    while (_randomIndexes.length < kNumOfSeedWordsToBeFound) {
      _generateRandomIndex();
    }
  }

  void _generateRandomIndex() {
    int randomNumber = Random().nextInt(_seedGridElements.length);
    if (!_randomIndexes.contains(randomNumber)) {
      _randomIndexes.add(randomNumber);
    }
  }

  Color _getColor(SeedGridElement seedGridElement, bool border) {
    if (_randomIndexes.contains(_seedGridElements.indexOf(seedGridElement))) {
      if (seedGridElement.isValid == true && _seedError == true) {
        return AppColors.znnColor;
      } else if (!seedGridElement.isValid && _seedError == true) {
        return AppColors.errorColor;
      } else {
        if (border) {
          return AppColors.seedUnderlineBorderColor;
        } else {
          return Theme.of(context).colorScheme.secondaryContainer;
        }
      }
    } else if (seedGridElement.isValid && border == false) {
      return AppColors.znnColor;
    } else {
      if (border) {
        return AppColors.seedUnderlineBorderColor;
      } else {
        return Theme.of(context).colorScheme.secondaryContainer;
      }
    }
  }

  Widget _seedFieldWidget(SeedGridElement seedGridElement) {
    int seedGridElementIndex = _seedGridElements.indexOf(seedGridElement);

    final TextEditingController _controller = TextEditingController();
    _controller.text = seedGridElement.word;
    if (_textCursor == seedGridElementIndex) {
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }

    return SizedBox(
      width: 200.0,
      height: 30.0,
      child: Row(
        children: <Widget>[
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              setState(() {
                seedGridElement.isShown = !seedGridElement.isShown;
              });
            },
            child: FocusableActionDetector(
              onShowHoverHighlight: (x) {
                if (x) {
                  setState(() {
                    _hoveredSeedGridIndex = seedGridElementIndex;
                  });
                } else {
                  setState(() {
                    _hoveredSeedGridIndex = null;
                  });
                }
              },
              child: Container(
                width: 30.0,
                height: 30.0,
                decoration: BoxDecoration(
                    border: Border.all(
                      width: 2.0,
                      color: _hoveredSeedGridIndex == seedGridElementIndex ||
                              _randomIndexes.contains(seedGridElementIndex)
                          ? _getColor(seedGridElement, false)
                          : Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '${seedGridElementIndex + 1}',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 10.0,
          ),
          Expanded(
            child: FocusableActionDetector(
              onShowHoverHighlight: (x) {
                if (x) {
                  setState(() {
                    _hoveredSeedGridIndex = seedGridElementIndex;
                  });
                } else {
                  setState(() {
                    _hoveredSeedGridIndex = null;
                  });
                }
              },
              child: DragTarget<String>(
                builder: (BuildContext context, accepted, rejected) {
                  return TextField(
                    enabled: false,
                    controller: _controller,
                    obscureText: _randomIndexes.contains(seedGridElementIndex)
                        ? false
                        : !seedGridElement.isShown ||
                            _hoveredSeedGridIndex != seedGridElementIndex,
                    cursorColor: Colors.white,
                    style: TextStyle(
                      color: _hoveredSeedGridIndex == seedGridElementIndex ||
                              _randomIndexes.contains(seedGridElementIndex)
                          ? Colors.white
                          : AppColors.znnColor,
                      fontSize: 12.0,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withOpacity(0.9),
                      disabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _getColor(seedGridElement, true),
                          width: 3.0,
                        ),
                      ),
                      hintText: '',
                    ),
                  );
                },
                onWillAccept: (data) {
                  return _randomIndexes.contains(seedGridElementIndex) ||
                      !seedGridElement.isValid;
                },
                onAccept: (String data) {
                  _foundMissingRandomElementsIndexes
                      .add(widget.seedWords.indexOf(data));
                  _seedGridElements[seedGridElementIndex].word = data;
                  if (_randomIndexes.length ==
                      _foundMissingRandomElementsIndexes.length) {}
                  setState(() {
                    _textCursor = seedGridElementIndex;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getMissingSeedGridElements(List<String> seedWords) {
    List<Widget> list = <Widget>[];
    for (var index in _randomIndexes) {
      if (!_foundMissingRandomElementsIndexes.contains(index)) {
        list.add(
          Draggable<String>(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: _draggedValue == seedWords[index]
                    ? Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withOpacity(0.5)
                    : Theme.of(context).colorScheme.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              onPressed: () {},
              child: Text(
                seedWords[index],
                style: Theme.of(context).textTheme.bodyText1!.copyWith(
                      color: _draggedValue == seedWords[index]
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white,
                    ),
              ),
            ),
            feedback: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: AppColors.darkSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              onPressed: () {},
              child: Text(
                seedWords[index],
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            data: seedWords[index],
            onDragStarted: () {
              setState(() {
                _draggedValue = seedWords[index];
              });
            },
            onDragEnd: (_) {
              setState(() {
                _draggedValue = null;
              });
            },
          ),
        );
      }
    }
    return Wrap(
      children: list,
      crossAxisAlignment: WrapCrossAlignment.start,
      alignment: WrapAlignment.start,
      direction: Axis.horizontal,
      spacing: 5.0,
    );
  }

  void _checkSeed() {
    _seedError = false;
    for (var element in _seedGridElements) {
      int i = _seedGridElements.indexOf(element);
      element.isValid = element.word == widget.seedWords[i];
    }
    for (var item in _seedGridElements) {
      if (!item.isValid) {
        setState(() {
          _seedError = true;
        });
        break;
      }
    }
    setState(() {
      _foundMissingRandomElementsIndexes = _randomIndexes
          .where((index) => _seedGridElements[index].isValid)
          .toList();
      _actionButton =
          _foundMissingRandomElementsIndexes.length == kNumOfSeedWordsToBeFound
              ? _getContinueButton()
              : _getVerifyButton();
    });
  }

  Widget _getContinueButton() {
    return OnboardingButton(
      text: 'Continue',
      onPressed: () {
        NavigationUtils.push(
          context,
          NewWalletPasswordScreen(
            _seedGridElements.map((e) => e.word).toList(),
          ),
        );
      },
    );
  }

  Widget _getVerifyButton() {
    return OnboardingButton(
      text: 'Verify',
      onPressed: _checkSeed,
    );
  }

  Widget _getPassiveButton() {
    return OnboardingButton(
      onPressed: () {
        Navigator.pop(context);
      },
      text: 'Go back',
    );
  }

  Widget _getSeedInputWidgetsGrid() {
    int divider = widget.seedWords.length ~/ kSeedGridNumOfRows;

    List<Widget> columnChildren = [];

    for (int i = 0; i <= _seedGridElements.length / divider - 1; i++) {
      columnChildren.add(
        _getSeedRow(
          List.generate(
            divider,
            (index) => index + (divider * i),
          ),
        ),
      );
    }

    columnChildren = columnChildren.zip<Widget>(
      List.generate(
        kSeedGridNumOfRows - 1,
        (index) => const SizedBox(
          height: 10.0,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: columnChildren,
    );
  }

  Widget _getSeedRow(List<int> rangeIndexes) {
    List<Widget> children = rangeIndexes.fold<List<Widget>>(
      [],
      (previousValue, index) {
        previousValue.add(_seedFieldWidget(
          _seedGridElements[index],
        ));
        if (rangeIndexes.last != index) {
          previousValue.add(
            const SizedBox(
              width: 10.0,
            ),
          );
        }
        return previousValue;
      },
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
