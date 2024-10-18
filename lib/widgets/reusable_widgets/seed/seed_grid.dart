import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart' show Mnemonic;

class SeedGrid extends StatefulWidget {

  const SeedGrid(
    this.seedWords, {
    this.isContinueButtonDisabled = false,
    this.enableSeedInputFields = true,
    this.onTextFieldChangedCallback,
    super.key,
  });
  final List<String> seedWords;
  final bool isContinueButtonDisabled;
  final bool enableSeedInputFields;
  final VoidCallback? onTextFieldChangedCallback;

  @override
  State createState() {
    return SeedGridState();
  }
}

class SeedGridState extends State<SeedGrid> {
  final List<SeedGridElement> _seedGridElements = [];

  int? _textCursor;
  int? _onHoverText;

  bool? _seedError;
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
      ActivateIntent: CallbackAction(
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
    final divider = widget.seedWords.length ~/ kSeedGridNumOfRows;

    var columnChildren = <Widget>[];

    for (var i = 0; i <= widget.seedWords.length / divider - 1; i++) {
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: columnChildren,
    );
  }

  Widget _getSeedRow(List<int> rangeIndexes) {
    final children = rangeIndexes.fold<List<Widget>>(
      [],
      (previousValue, index) {
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
    final seedWord = _seedGridElements[seedWordIndex].word;

    final controller = TextEditingController();
    controller.text = seedWord;

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
              onShowHoverHighlight: (x) {
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
              onShowHoverHighlight: (x) {
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
                  onChanged: (text) {
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
                  inputFormatters: [LengthLimitingTextInputFormatter(8)],
                  enabled: widget.enableSeedInputFields,
                  controller: controller,
                  obscureText: _onHoverText == seedWordIndex
                      ? false
                      : _seedGridElements[seedWordIndex].isShown,
                  cursorColor: Colors.white,
                  style: TextStyle(
                    color: _seedGridElements[seedWordIndex].isShown == false ||
                            _onHoverText == seedWordIndex
                        ? Colors.white
                        : getIndicatorColor(seedWord),
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withOpacity(0.9),
                    border: _getBorder(
                      seedWord,
                      _seedGridElements[seedWordIndex].isShown == false ||
                          _onHoverText == seedWordIndex,
                    ),
                    focusedBorder: _getBorder(
                      seedWord,
                      _seedGridElements[seedWordIndex].isShown == false ||
                          _onHoverText == seedWordIndex,
                    ),
                    enabledBorder: _getBorder(
                      seedWord,
                      _seedGridElements[seedWordIndex].isShown == false ||
                          _onHoverText == seedWordIndex,
                    ),
                    disabledBorder: _getBorder(
                      seedWord,
                      _seedGridElements[seedWordIndex].isShown == false ||
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
    return _seedGridElements[seedIndex].isShown == false
        ? getIndicatorColor(seedValue)
        : Theme.of(context).colorScheme.secondaryContainer;
  }

  Color getIndicatorColor(String seedValue) {
    if (Mnemonic.isValidWord(seedValue)) {
      return AppColors.znnColor;
    } else if (Mnemonic.isValidWord(seedValue) == false && seedValue != '' ||
        (seedValue == '' && _seedError == true)) {
      return AppColors.errorColor;
    } else {
      return AppColors.seedUnderlineBorderColor;
    }
  }

  Color _getSeedNumberBorderColor(int seedIndex, String seedValue) {
    return _onHoverText == seedIndex ||
            _seedGridElements[seedIndex].isShown == false
        ? getIndicatorColor(seedValue)
        : Theme.of(context).colorScheme.secondaryContainer;
  }

  UnderlineInputBorder _getBorder(String seedValue, normal) {
    if (normal == false) {
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
    } else if (Mnemonic.isValidWord(seedValue) == false && seedValue != '' ||
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
    return _seedGridElements.any((element) => !element.isValid);
  }

  void changedSeed(List<String> newSeed) {
    setState(() {
      _seedGridElements.clear();
      _initFocusNodes(newSeed.length);
      _initSeedGridElements(newSeed);
    });
  }

  List<String> get getSeedWords =>
      _seedGridElements.map((e) => e.word).toList();

  String get getSeed => getSeedWords.join(' ');

  void _initFocusNodes(int length) => _focusNodes = List.generate(
        length,
        (index) => FocusNode(),
      );

  void _changeFocusToNextNode() {
    final indexOfFocusedNode = _focusNodes.indexOf(
      _focusNodes.firstWhere(
        (node) => node.hasFocus,
      ),
    );
    if (indexOfFocusedNode + 1 < _focusNodes.length) {
      _focusNodes[indexOfFocusedNode + 1].requestFocus();
    } else {
      _focusNodes[0].requestFocus();
    }
  }

  void _initSeedGridElements(List<String> seed) {
    for (final word in seed) {
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
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}

class SeedGridElement {

  SeedGridElement({
    required this.word,
    required this.isValid,
    required this.isShown,
  });
  String word;
  bool isValid;
  bool isShown;
}
