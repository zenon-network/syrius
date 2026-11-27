import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart' show Mnemonic;

/// Interactive grid of mnemonic seed word inputs with validation indicators.
class SeedGrid extends StatefulWidget {
  /// Creates a [SeedGrid].
  const SeedGrid(
    this.seedWords, {
    this.isContinueButtonDisabled = false,
    this.enableSeedInputFields = true,
    this.onTextFieldChangedCallback,
    super.key,
  });

  /// Initial list of mnemonic seed words displayed in the grid.
  final List<String> seedWords;

  /// Initial disabled state for the parent flow's continue button.
  final bool isContinueButtonDisabled;

  /// Whether the individual seed word fields accept user input.
  final bool enableSeedInputFields;

  /// Optional callback invoked whenever any seed word field changes.
  final VoidCallback? onTextFieldChangedCallback;

  @override
  State createState() {
    return SeedGridState();
  }
}

/// State object for [SeedGrid] providing access to the edited mnemonic words.
class SeedGridState extends State<SeedGrid> {
  final List<SeedGridElement> _seedGridElements = <SeedGridElement>[];

  int? _textCursor;
  int? _onHoverText;

  bool? _seedError;

  /// Whether the parent continue action should remain disabled due to invalid
  /// seed words.
  bool? continueButtonDisabled;

  late List<FocusNode> _focusNodes;

  Map<Type, Action<Intent>>? _actionMap;
  Map<LogicalKeySet, Intent>? _shortcutMap;

  @override
  void initState() {
    super.initState();
    _initSeedGridElements(widget.seedWords);
    _initFocusNodes(_seedGridElements.length);
    continueButtonDisabled = widget.isContinueButtonDisabled;
    _actionMap = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<Intent>(
        onInvoke: (Intent intent) => _changeFocusToNextNode(),
      ),
    };
    _shortcutMap = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.tab): const ActivateIntent(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _getSeedInputWidgetsGrid();
  }

  Widget _getSeedInputWidgetsGrid() {
    final int divider = widget.seedWords.length ~/ kSeedGridNumOfRows;

    List<Widget> columnChildren = <Widget>[];

    for (int i = 0; i <= widget.seedWords.length / divider - 1; i++) {
      columnChildren.add(
        _getSeedRow(
          List<int>.generate(
            divider,
            (int index) => index + (divider * i),
          ),
        ),
      );
    }

    columnChildren = columnChildren.zip<Widget>(
      List<Widget>.generate(
        kSeedGridNumOfRows - 1,
        (int index) => const SizedBox(
          height: 10,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: columnChildren,
    );
  }

  Widget _getSeedRow(List<int> rangeIndexes) {
    final List<Widget> children = rangeIndexes.fold<List<Widget>>(
      <Widget>[],
      (List<Widget> previousValue, int index) {
        previousValue.add(_seedWordWidget(index));
        if (rangeIndexes.last != index) {
          previousValue.add(const SizedBox(
            width: 10,
          ),);
        }
        return previousValue;
      },
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  Widget _seedWordWidget(int seedWordIndex) {
    final String seedWord = _seedGridElements[seedWordIndex].word;

    final TextEditingController controller = TextEditingController()
      ..text = seedWord;

    if (_textCursor == seedWordIndex) {
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
    return SizedBox(
      width: kSeedWordCellWidth,
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              _seedGridElements[seedWordIndex].isShown =
                  !_seedGridElements[seedWordIndex].isShown;
            },
            child: FocusableActionDetector(
              mouseCursor: SystemMouseCursors.click,
              onShowHoverHighlight: (bool x) {
                if (x) {
                  setState(() {
                    _onHoverText = seedWordIndex;
                  });
                } else {
                  setState(() {
                    _onHoverText = null;
                  });
                }
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: _getSeedNumberBorderColor(seedWordIndex, seedWord),
                  ),
                  color: _getSeedNumberColor(seedWordIndex, seedWord),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (seedWordIndex + 1).toString(),
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Colors.white,
                        ),
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
              actions: _actionMap,
              shortcuts: _shortcutMap,
              onShowHoverHighlight: (bool x) {
                if (x) {
                  setState(() {
                    _onHoverText = seedWordIndex;
                  });
                } else {
                  setState(() {
                    _onHoverText = null;
                  });
                }
              },
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  focusNode: _focusNodes[seedWordIndex],
                  onChanged: (String text) {
                    controller.text = text;
                    _seedGridElements[seedWordIndex].word = text;
                    _seedGridElements[seedWordIndex].isValid =
                        Mnemonic.isValidWord(text);
                    setState(() {
                      _textCursor = seedWordIndex;
                    });
                    _checkIfSeedIsValid();
                    widget.onTextFieldChangedCallback?.call();
                  },
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(8),
                  ],
                  enabled: widget.enableSeedInputFields,
                  controller: controller,
                  obscureText:
                      _onHoverText != seedWordIndex &&
                      _seedGridElements[seedWordIndex].isShown,
                  cursorColor: Colors.white,
                  style: TextStyle(
                    color:
                        !_seedGridElements[seedWordIndex].isShown ||
                            _onHoverText == seedWordIndex
                        ? Colors.white
                        : getIndicatorColor(seedWord),
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
                    border: _getBorder(
                      seedWord,
                      !_seedGridElements[seedWordIndex].isShown ||
                          _onHoverText == seedWordIndex,
                    ),
                    focusedBorder: _getBorder(
                      seedWord,
                      !_seedGridElements[seedWordIndex].isShown ||
                          _onHoverText == seedWordIndex,
                    ),
                    enabledBorder: _getBorder(
                      seedWord,
                      !_seedGridElements[seedWordIndex].isShown ||
                          _onHoverText == seedWordIndex,
                    ),
                    disabledBorder: _getBorder(
                      seedWord,
                      !_seedGridElements[seedWordIndex].isShown ||
                          _onHoverText == seedWordIndex,
                    ),
                    hintText: '',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeedNumberColor(int seedIndex, String seedValue) {
    return !_seedGridElements[seedIndex].isShown
        ? getIndicatorColor(seedValue)
        : Theme.of(context).colorScheme.secondaryContainer;
  }

  /// Returns the validation status indicator color for [seedValue].
  Color getIndicatorColor(String seedValue) {
    if (Mnemonic.isValidWord(seedValue)) {
      return AppColors.znnColor;
    } else if (!Mnemonic.isValidWord(seedValue) && seedValue != '' ||
        (seedValue == '' && _seedError == true)) {
      return AppColors.errorColor;
    } else {
      return AppColors.seedUnderlineBorderColor;
    }
  }

  Color _getSeedNumberBorderColor(int seedIndex, String seedValue) {
    return _onHoverText == seedIndex || !_seedGridElements[seedIndex].isShown
        ? getIndicatorColor(seedValue)
        : Theme.of(context).colorScheme.secondaryContainer;
  }

  UnderlineInputBorder _getBorder(String seedValue, bool normal) {
    if (!normal) {
      return const UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.seedUnderlineBorderColor,
          width: 3,
        ),
      );
    } else if (Mnemonic.isValidWord(seedValue)) {
      return const UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.znnColor,
          width: 3,
        ),
      );
    } else if (!Mnemonic.isValidWord(seedValue) && seedValue != '' ||
        (seedValue == '' && _seedError == true)) {
      return const UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.errorColor,
          width: 3,
        ),
      );
    } else {
      return const UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.seedUnderlineBorderColor,
          width: 3,
        ),
      );
    }
  }

  void _checkIfSeedIsValid() {
    _seedError = false;
    continueButtonDisabled = false;
    if (_foundInvalidSeedGridElement()) {
      _seedError = true;
      continueButtonDisabled = true;
    }
    setState(() {});
  }

  bool _foundInvalidSeedGridElement() {
    return _seedGridElements.any((SeedGridElement element) => !element.isValid);
  }

  /// Replaces the displayed seed words with [newSeed].
  void changedSeed(List<String> newSeed) {
    setState(() {
      _seedGridElements.clear();
      _initFocusNodes(newSeed.length);
      _initSeedGridElements(newSeed);
    });
  }

  /// Returns the current list of entered seed words.
  List<String> get getSeedWords =>
      _seedGridElements.map((SeedGridElement e) => e.word).toList();

  /// Returns the current seed words joined by spaces.
  String get getSeed => getSeedWords.join(' ');

  void _initFocusNodes(int length) => _focusNodes = List<FocusNode>.generate(
        length,
        (int index) => FocusNode(),
      );

  void _changeFocusToNextNode() {
    final int indexOfFocusedNode = _focusNodes.indexOf(
      _focusNodes.firstWhere(
        (FocusNode node) => node.hasFocus,
      ),
    );
    if (indexOfFocusedNode + 1 < _focusNodes.length) {
      _focusNodes[indexOfFocusedNode + 1].requestFocus();
    } else {
      _focusNodes[0].requestFocus();
    }
  }

  void _initSeedGridElements(List<String> seed) {
    for (final String word in seed) {
      _seedGridElements.add(
        SeedGridElement(
          word: word,
          isValid: Mnemonic.isValidWord(word),
          isShown: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final FocusNode focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}

/// Mutable state for a single seed word cell inside [SeedGrid].
class SeedGridElement {
  /// Creates a [SeedGridElement].
  SeedGridElement({
    required this.word,
    required this.isValid,
    required this.isShown,
  });

  /// Mnemonic word text in this cell.
  String word;

  /// Whether [word] is a valid BIP-39 mnemonic word.
  bool isValid;

  /// Whether the cell currently obscures [word].
  bool isShown;
}
