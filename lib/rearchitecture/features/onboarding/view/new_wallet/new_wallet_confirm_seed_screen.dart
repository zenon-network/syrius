import 'dart:math';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Screen asking the user to drag and drop missing seed words to confirm
/// backup.
class NewWalletConfirmSeedScreen extends StatelessWidget {
  /// Creates a [NewWalletConfirmSeedScreen].
  const NewWalletConfirmSeedScreen(
    this._seedWords, {
    this._randomIndexes,
    super.key,
  });

  final List<String> _seedWords;
  final List<int>? _randomIndexes;

  @override
  Widget build(BuildContext context) {
    return _View(seedWords: _seedWords, randomIndexes: _randomIndexes);
  }
}

class _View extends StatefulWidget {
  const _View({required this._seedWords, this._randomIndexes});

  final List<String> _seedWords;
  final List<int>? _randomIndexes;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  bool _seedError = false;
  bool _isSeedVerified = false;
  int? _hoveredSeedGridIndex;
  int? _textCursor;
  String? _draggedValue;

  final List<SeedGridElement> _seedGridElements = <SeedGridElement>[];
  final List<TextEditingController> _controllers = <TextEditingController>[];
  final List<int> _randomIndexes = <int>[];
  List<int> _foundMissingRandomElementsIndexes = <int>[];

  @override
  void initState() {
    super.initState();
    for (final String word in widget._seedWords) {
      _seedGridElements.add(
        SeedGridElement(word: word, isValid: true, isShown: true),
      );
      _controllers.add(TextEditingController(text: word));
    }
    _initRandomIndexes();
    for (final int index in _randomIndexes) {
      _seedGridElements[index].word = '';
      _controllers[index].text = '';
    }
  }

  void _initRandomIndexes() {
    final List<int>? injectedIndexes = widget._randomIndexes;
    if (injectedIndexes != null) {
      _randomIndexes.addAll(injectedIndexes);
      return;
    }
    final Random random = Random();
    final int targetCount = min(
      kNumOfSeedWordsToBeFound,
      _seedGridElements.length,
    );
    while (_randomIndexes.length < targetCount) {
      final int randomNumber = random.nextInt(_seedGridElements.length);
      if (!_randomIndexes.contains(randomNumber)) {
        _randomIndexes.add(randomNumber);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: <Widget>[
                const ProgressBar(currentLevel: 2),
                const SizedBox(height: 30),
                Text(
                  context.l10n.confirmYourSeed,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                kVerticalSpacing,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      context.l10n.dragAndDropWordsCorrectOrder,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    StandardTooltipIcon(
                      context.l10n.dragAndDropWordsOnEmptyOrIncorrect,
                      Icons.help,
                    ),
                  ],
                ),
                const SizedBox(height: 75),
                _buildSeedInputWidgetsGrid(context),
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(left: 90),
                  child: _buildMissingSeedGridElements(
                    context,
                    widget._seedWords,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildGoBackButton(context),
                kSpacingBetweenActionButtons,
                if (_isSeedVerified)
                  _buildContinueButton(context)
                else
                  _buildVerifyButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(
    BuildContext context,
    int seedGridElementIndex,
    SeedGridElement seedGridElement, {
    required bool isBorder,
  }) {
    if (_randomIndexes.contains(seedGridElementIndex)) {
      if (seedGridElement.isValid && _seedError) {
        return AppColors.znnColor;
      } else if (!seedGridElement.isValid && _seedError) {
        return AppColors.errorColor;
      } else {
        return isBorder
            ? AppColors.seedUnderlineBorderColor
            : Theme.of(context).colorScheme.secondaryContainer;
      }
    } else if (seedGridElement.isValid && !isBorder) {
      return AppColors.znnColor;
    } else {
      return isBorder
          ? AppColors.seedUnderlineBorderColor
          : Theme.of(context).colorScheme.secondaryContainer;
    }
  }

  Widget _buildSeedFieldWidget(BuildContext context, int seedGridElementIndex) {
    final SeedGridElement seedGridElement =
        _seedGridElements[seedGridElementIndex];
    final TextEditingController controller = _controllers[seedGridElementIndex];
    if (controller.text != seedGridElement.word) {
      controller.text = seedGridElement.word;
    }
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
              onShowHoverHighlight: (bool isHovered) {
                setState(() {
                  _hoveredSeedGridIndex = isHovered
                      ? seedGridElementIndex
                      : null;
                });
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color:
                        _hoveredSeedGridIndex == seedGridElementIndex ||
                            _randomIndexes.contains(seedGridElementIndex)
                        ? _getColor(
                            context,
                            seedGridElementIndex,
                            seedGridElement,
                            isBorder: false,
                          )
                        : Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${seedGridElementIndex + 1}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FocusableActionDetector(
              onShowHoverHighlight: (bool isHovered) {
                setState(() {
                  _hoveredSeedGridIndex = isHovered
                      ? seedGridElementIndex
                      : null;
                });
              },
              child: DragTarget<String>(
                builder:
                    (
                      BuildContext context,
                      List<String?> accepted,
                      List<dynamic> rejected,
                    ) {
                      return TextField(
                        enabled: false,
                        controller: controller,
                        obscureText:
                            !_randomIndexes.contains(seedGridElementIndex) &&
                            (!seedGridElement.isShown ||
                                _hoveredSeedGridIndex != seedGridElementIndex),
                        cursorColor: Colors.white,
                        style: TextStyle(
                          color:
                              _hoveredSeedGridIndex == seedGridElementIndex ||
                                  _randomIndexes.contains(seedGridElementIndex)
                              ? Colors.white
                              : AppColors.znnColor,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(8),
                          isDense: true,
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.9),
                          disabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: _getColor(
                                context,
                                seedGridElementIndex,
                                seedGridElement,
                                isBorder: true,
                              ),
                              width: 3,
                            ),
                          ),
                          hintText: '',
                        ),
                      );
                    },
                onWillAcceptWithDetails: (DragTargetDetails<String> details) {
                  return _randomIndexes.contains(seedGridElementIndex) ||
                      !seedGridElement.isValid;
                },
                onAcceptWithDetails: (DragTargetDetails<String> details) {
                  final SeedGridElement element =
                      _seedGridElements[seedGridElementIndex];
                  int i = -1;
                  if (element.word.isNotEmpty) {
                    while ((i = widget._seedWords.indexOf(
                          element.word,
                          i + 1,
                        )) !=
                        -1) {
                      if (_foundMissingRandomElementsIndexes.contains(i)) {
                        _foundMissingRandomElementsIndexes.remove(i);
                        break;
                      }
                    }
                  }
                  i = -1;
                  while ((i = widget._seedWords.indexOf(details.data, i + 1)) !=
                      -1) {
                    if (!_foundMissingRandomElementsIndexes.contains(i) &&
                        _randomIndexes.contains(i)) {
                      _foundMissingRandomElementsIndexes.add(i);
                      break;
                    }
                  }
                  element.word = details.data;
                  _controllers[seedGridElementIndex].text = details.data;
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

  Widget _buildMissingSeedGridElements(
    BuildContext context,
    List<String> seedWords,
  ) {
    final List<Widget> list = <Widget>[];
    for (final int index in _randomIndexes) {
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
                    ? Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withValues(alpha: 0.5)
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
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.white,
                ),
              ),
            ),
          ),
        );
      }
    }
    return Wrap(spacing: 5, children: list);
  }

  void _checkSeed() {
    bool hasError = false;
    for (int i = 0; i < _seedGridElements.length; i++) {
      final SeedGridElement element = _seedGridElements[i];
      element.isValid = element.word == widget._seedWords[i];
      if (!element.isValid) {
        hasError = true;
      }
    }
    if (hasError) {
      for (int i = 0; i < _seedGridElements.length; i++) {
        if (_randomIndexes.contains(i)) {
          _seedGridElements[i].isValid = false;
          _seedGridElements[i].word = '';
          _controllers[i].text = '';
        }
      }
    }

    setState(() {
      _seedError = true;
      _foundMissingRandomElementsIndexes = _randomIndexes
          .where((int index) => _seedGridElements[index].isValid)
          .toList();
      _isSeedVerified =
          _foundMissingRandomElementsIndexes.length == _randomIndexes.length;
    });
  }

  Widget _buildContinueButton(BuildContext context) {
    return OnboardingButton(
      text: context.l10n.continueText,
      onPressed: () {
        NavigationUtils.push(
          context,
          NewWalletPasswordScreen(
            _seedGridElements
                .map<String>((SeedGridElement e) => e.word)
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildVerifyButton(BuildContext context) {
    return OnboardingButton(text: context.l10n.verify, onPressed: _checkSeed);
  }

  Widget _buildGoBackButton(BuildContext context) {
    return OnboardingButton(
      onPressed: () => Navigator.pop(context),
      text: context.l10n.goBack,
    );
  }

  Widget _buildSeedInputWidgetsGrid(BuildContext context) {
    final int divider = widget._seedWords.length ~/ kSeedGridNumOfRows;

    List<Widget> columnChildren = <Widget>[];

    for (int i = 0; i <= _seedGridElements.length / divider - 1; i++) {
      columnChildren.add(
        _buildSeedRow(
          context,
          List<int>.generate(divider, (int index) => index + (divider * i)),
        ),
      );
    }

    columnChildren = columnChildren.zip<Widget>(
      List<Widget>.generate(
        kSeedGridNumOfRows - 1,
        (int index) => const SizedBox(height: 10),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: columnChildren,
    );
  }

  Widget _buildSeedRow(BuildContext context, List<int> rangeIndexes) {
    final List<Widget> children = rangeIndexes.fold<List<Widget>>(<Widget>[], (
      List<Widget> previousValue,
      int index,
    ) {
      previousValue.add(_buildSeedFieldWidget(context, index));
      if (rangeIndexes.last != index) {
        previousValue.add(const SizedBox(width: 10));
      }
      return previousValue;
    });
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
