import 'dart:math';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Screen asking the user to confirm specific seed words (Screen 46).
///
/// Supports both single-click quiz pills and drag-and-drop [DragTarget<String>]
/// for full test compatibility.
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
  final List<int> _randomIndexes = <int>[];
  final Map<int, String> _selectedWords = <int, String>{};
  final Map<int, List<String>> _choicesByIndex = <int, List<String>>{};
  bool _hasError = false;
  bool _isSeedVerified = false;

  @override
  void initState() {
    super.initState();
    _initRandomIndexes();
    _buildChoices();
  }

  void _initRandomIndexes() {
    final List<int>? injected = widget._randomIndexes;
    if (injected != null) {
      _randomIndexes.addAll(injected);
      return;
    }
    final Random random = Random();
    final int targetCount = min(3, widget._seedWords.length);
    while (_randomIndexes.length < targetCount) {
      final int pick = random.nextInt(widget._seedWords.length);
      if (!_randomIndexes.contains(pick)) {
        _randomIndexes.add(pick);
      }
    }
    _randomIndexes.sort();
  }

  void _buildChoices() {
    final Random random = Random(42);
    for (final int idx in _randomIndexes) {
      final String correct = widget._seedWords[idx];
      final Set<String> options = <String>{correct};
      final List<String> pool = List<String>.of(widget._seedWords)
        ..shuffle(random);
      for (final String w in pool) {
        if (options.length >= 4) {
          break;
        }
        options.add(w);
      }
      final List<String> shuffled = options.toList()..shuffle(random);
      _choicesByIndex[idx] = shuffled;
    }
  }

  void _checkSeed() {
    bool allMatch = true;
    for (final int idx in _randomIndexes) {
      if (_selectedWords[idx] != widget._seedWords[idx]) {
        allMatch = false;
        break;
      }
    }
    if (!allMatch) {
      setState(() {
        _hasError = true;
        _isSeedVerified = false;
        _selectedWords.clear();
      });
      return;
    }
    setState(() {
      _hasError = false;
      _isSeedVerified = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final int answeredCount = _selectedWords.length;

    return Scaffold(
      body: SyriusAmbientBackdrop(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 16,
              left: 18,
              child: Text(
                'S Y R I U S',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 3.5,
                  color: tokens.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: SyriusCard(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            SyriusGhostButton(
                              label: context.l10n.back,
                              icon: Icons.chevron_left,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.l10n.confirmYourSeed,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SyriusHorizontalStepper(
                          steps: <String>[
                            context.l10n.seed,
                            context.l10n.confirm,
                            context.l10n.password,
                            context.l10n.ready,
                          ],
                          currentStep: 1,
                        ),
                        const SizedBox(height: 22),
                        for (
                          int i = 0;
                          i < _randomIndexes.length;
                          i++
                        ) ...<Widget>[
                          if (i > 0) Divider(height: 1, color: tokens.border),
                          _buildQuizRow(context, tokens, _randomIndexes[i]),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: <Widget>[
                            Text(
                              _hasError
                                  ? context.l10n.mnemonicIsNotValid
                                  : '$answeredCount of '
                                        '${_randomIndexes.length} done.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _hasError
                                    ? tokens.error
                                    : tokens.textMuted,
                              ),
                            ),
                            const Spacer(),
                            if (_isSeedVerified)
                              OnboardingButton(
                                text: context.l10n.continueText,
                                onPressed: () {
                                  NavigationUtils.push(
                                    context,
                                    NewWalletPasswordScreen(widget._seedWords),
                                  );
                                },
                              )
                            else
                              OnboardingButton(
                                text: context.l10n.verify,
                                onPressed: _checkSeed,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizRow(
    BuildContext context,
    SyriusThemeTokens tokens,
    int wordIndex,
  ) {
    final String? chosen = _selectedWords[wordIndex];
    final List<String> options = _choicesByIndex[wordIndex] ?? const <String>[];

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (DragTargetDetails<String> details) {
        setState(() {
          _hasError = false;
          _selectedWords[wordIndex] = details.data;
        });
      },
      builder: (_, _, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 96,
                child: Text(
                  'Word ${wordIndex + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((String word) {
                    final bool selected = chosen == word;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _hasError = false;
                          _selectedWords[wordIndex] = word;
                        });
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? tokens.surfaceElevated
                              : tokens.surfaceSubtle,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? tokens.textPrimary
                                : tokens.border,
                          ),
                        ),
                        child: Text(
                          word,
                          style: tokens.monoStyle(
                            fontSize: 12.5,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? tokens.textPrimary
                                : tokens.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
