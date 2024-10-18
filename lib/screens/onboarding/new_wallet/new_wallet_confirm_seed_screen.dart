import 'dart:math';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class NewWalletConfirmSeedScreen extends StatefulWidget {

  const NewWalletConfirmSeedScreen(
    this.seedWords, {
    super.key,
  });
  final List<String> seedWords;

  @override
  State<NewWalletConfirmSeedScreen> createState() =>
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
    for (final word in widget.seedWords) {
      _seedGridElements.add(
        SeedGridElement(
          word: word,
          isValid: true,
          isShown: true,
        ),
      );
    }
    _generateRandomIndexes();
    for (final index in _randomIndexes) {
      _seedGridElements[index].word = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30,
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
                  height: 30,
                ),
                Text(
                  'Confirm your seed',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                kVerticalSpacing,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Drag & drop the words in the correct order',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const StandardTooltipIcon(
                      'You can drag & drop words on empty boxes or incorrect words',
                      Icons.help,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 75,
                ),
                _getSeedInputWidgetsGrid(),
              ],
            ),
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 90),
                  child: _getMissingSeedGridElements(widget.seedWords),
                ),
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
    final randomNumber = Random().nextInt(_seedGridElements.length);
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
    final seedGridElementIndex = _seedGridElements.indexOf(seedGridElement);

    final controller = TextEditingController();
    controller.text = seedGridElement.word;
    if (_textCursor == seedGridElementIndex) {
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }

    return SizedBox(
      width: 200,
      height: 30,
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    border: Border.all(
                      width: 2,
                      color: _hoveredSeedGridIndex == seedGridElementIndex ||
                              _randomIndexes.contains(seedGridElementIndex)
                          ? _getColor(seedGridElement, false)
                          : Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    shape: BoxShape.circle,),
                child: Center(
                  child: Text(
                    '${seedGridElementIndex + 1}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 10,
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
                    controller: controller,
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
                      fontSize: 12,
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
                          width: 3,
                        ),
                      ),
                      hintText: '',
                    ),
                  );
                },
                onWillAcceptWithDetails: (data) {
                  return _randomIndexes.contains(seedGridElementIndex) ||
                      !seedGridElement.isValid;
                },
                onAcceptWithDetails: (DragTargetDetails data) {
                  final element = _seedGridElements[seedGridElementIndex];
                  var i = -1;
                  if (element.word != '') {
                    while ((i =
                            widget.seedWords.indexOf(element.word, i + 1)) !=
                        -1) {
                      if (_foundMissingRandomElementsIndexes.contains(i)) {
                        _foundMissingRandomElementsIndexes.remove(i);
                        break;
                      }
                    }
                  }
                  i = -1;
                  while ((i = widget.seedWords.indexOf(data.data, i + 1)) != -1) {
                    if (!_foundMissingRandomElementsIndexes.contains(i) &&
                        _randomIndexes.contains(i)) {
                      _foundMissingRandomElementsIndexes.add(i);
                      break;
                    }
                  }
                  element.word = data.data;
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
    final list = <Widget>[];
    for (final index in _randomIndexes) {
      if (!_foundMissingRandomElementsIndexes.contains(index)) {
        list.add(
          Draggable<String>(
            feedback: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.darkSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () {},
              child: Text(
                seedWords[index],
                style: Theme.of(context).textTheme.bodyLarge,
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
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: _draggedValue == seedWords[index]
                    ? Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withOpacity(0.5)
                    : Theme.of(context).colorScheme.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () {},
              child: Text(
                seedWords[index],
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: _draggedValue == seedWords[index]
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white,
                    ),
              ),
            ),
          ),
        );
      }
    }
    return Wrap(
      spacing: 5,
      children: list,
    );
  }

  void _checkSeed() {
    _seedError = false;
    for (final element in _seedGridElements) {
      final i = _seedGridElements.indexOf(element);
      element.isValid = element.word == widget.seedWords[i];
      if (!element.isValid) {
        _seedError = true;
      }
    }
    if (_seedError) {
      for (final element in _seedGridElements) {
        final i = _seedGridElements.indexOf(element);
        if (_randomIndexes.contains(i)) {
          element.isValid = false;
          element.word = '';
        }
      }
    }

    setState(() {
      _seedError = true;
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
    final divider = widget.seedWords.length ~/ kSeedGridNumOfRows;

    var columnChildren = <Widget>[];

    for (var i = 0; i <= _seedGridElements.length / divider - 1; i++) {
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
          height: 10,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: columnChildren,
    );
  }

  Widget _getSeedRow(List<int> rangeIndexes) {
    final children = rangeIndexes.fold<List<Widget>>(
      [],
      (previousValue, index) {
        previousValue.add(_seedFieldWidget(
          _seedGridElements[index],
        ),);
        if (rangeIndexes.last != index) {
          previousValue.add(
            const SizedBox(
              width: 10,
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
