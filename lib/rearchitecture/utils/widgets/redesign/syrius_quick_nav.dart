import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/redesign/syrius_modal.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';

/// Action command returned by [showSyriusQuickNavDialog].
class QuickNavCommand {
  /// Creates a [QuickNavCommand].
  const QuickNavCommand({
    required this.id,
    required this.category,
    required this.title,
    required this.icon,
    this.subtitle,
    this.shortcutHint,
    this.trailingLabel,
    this.tab,
    this.address,
  });

  /// Unique command identifier.
  final String id;

  /// Group header (`PAGES`, `ACTIONS`, `ADDRESSES`).
  final String category;

  /// Primary command label.
  final String title;

  /// Leading icon.
  final IconData icon;

  /// Optional secondary metadata beside [title].
  final String? subtitle;

  /// Optional keyboard shortcut badge (e.g. `Ctrl 4`).
  final String? shortcutHint;

  /// Optional muted trailing action label (e.g. `Send to`).
  final String? trailingLabel;

  /// Optional destination tab.
  final Tabs? tab;

  /// Optional target address for quick send.
  final String? address;
}

/// Opens the Ctrl+K Quick Navigation command palette matching Screen 05.
Future<QuickNavCommand?> showSyriusQuickNavDialog({
  required BuildContext context,
  required List<QuickNavCommand> commands,
}) {
  return showSyriusBlurredDialog<QuickNavCommand>(
    context: context,
    maxWidth: 560,
    builder: (BuildContext dialogContext) =>
        _QuickNavPalette(commands: commands),
  );
}

class _QuickNavPalette extends StatefulWidget {
  const _QuickNavPalette({required this.commands});

  final List<QuickNavCommand> commands;

  @override
  State<_QuickNavPalette> createState() => _QuickNavPaletteState();
}

class _QuickNavPaletteState extends State<_QuickNavPalette> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  int _selectedIndex = 0;

  List<QuickNavCommand> get _filtered {
    final String q = _queryController.text.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.commands.take(12).toList();
    }
    return widget.commands
        .where((QuickNavCommand c) {
          final String hay =
              '${c.title} ${c.subtitle ?? ''} ${c.category} ${c.address ?? ''}'
                  .toLowerCase();
          return hay.contains(q);
        })
        .take(12)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _moveSelection(int delta) {
    final List<QuickNavCommand> items = _filtered;
    if (items.isEmpty) {
      return;
    }
    setState(() {
      _selectedIndex = (_selectedIndex + delta) % items.length;
      if (_selectedIndex < 0) {
        _selectedIndex += items.length;
      }
    });
  }

  void _confirmSelection() {
    final List<QuickNavCommand> items = _filtered;
    if (items.isEmpty) {
      return;
    }
    final int idx = _selectedIndex.clamp(0, items.length - 1);
    Navigator.of(context).pop(items[idx]);
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final List<QuickNavCommand> items = _filtered;
    final int safeIndex = items.isEmpty
        ? 0
        : _selectedIndex.clamp(0, items.length - 1);

    final Map<String, List<QuickNavCommand>> grouped =
        <String, List<QuickNavCommand>>{};
    for (final QuickNavCommand cmd in items) {
      grouped.putIfAbsent(cmd.category, () => <QuickNavCommand>[]).add(cmd);
    }

    int runningIndex = 0;

    return Focus(
      onKeyEvent: (_, KeyEvent event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _moveSelection(1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _moveSelection(-1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          _confirmSelection();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
              child: Row(
                children: <Widget>[
                  Icon(Icons.search, size: 18, color: tokens.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      focusNode: _inputFocusNode,
                      onChanged: (_) => setState(() => _selectedIndex = 0),
                      style: TextStyle(
                        fontSize: 14.5,
                        color: tokens.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        hintText: context.l10n.quickNavigationHint,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: tokens.textMuted,
                        ),
                      ),
                    ),
                  ),
                  _KeyCap(label: 'Esc', tokens: tokens),
                ],
              ),
            ),
            Divider(height: 1, color: tokens.border),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          context.l10n.noItemsFound,
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.textMuted,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      children: <Widget>[
                        for (final MapEntry<String, List<QuickNavCommand>> entry
                            in grouped.entries) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                            child: Text(
                              entry.key.toUpperCase(),
                              style: tokens.microLabelStyle(),
                            ),
                          ),
                          for (final QuickNavCommand cmd in entry.value)
                            Builder(
                              builder: (BuildContext context) {
                                final int itemIndex = runningIndex++;
                                final bool selected = itemIndex == safeIndex;
                                return _CommandRow(
                                  command: cmd,
                                  selected: selected,
                                  onHover: () => setState(
                                    () => _selectedIndex = itemIndex,
                                  ),
                                  onTap: () => Navigator.of(context).pop(cmd),
                                );
                              },
                            ),
                        ],
                      ],
                    ),
            ),
            Divider(height: 1, color: tokens.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _FooterHint(keys: '↑↓', label: 'move', tokens: tokens),
                  _FooterHint(keys: '↵', label: 'open', tokens: tokens),
                  _FooterHint(keys: 'Ctrl 1–8', label: 'pages', tokens: tokens),
                  _FooterHint(keys: 'Ctrl L', label: 'lock', tokens: tokens),
                  _FooterHint(keys: 'Ctrl R', label: 'refresh', tokens: tokens),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({
    required this.command,
    required this.selected,
    required this.onHover,
    required this.onTap,
  });

  final QuickNavCommand command;
  final bool selected;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? tokens.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                command.icon,
                size: 16,
                color: selected ? tokens.textPrimary : tokens.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                command.title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: tokens.textPrimary,
                ),
              ),
              if (command.subtitle != null) ...<Widget>[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    command.subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.monoStyle(
                      fontSize: 12,
                      color: tokens.textMuted,
                    ),
                  ),
                ),
              ] else
                const Spacer(),
              if (command.shortcutHint != null)
                _KeyCap(label: command.shortcutHint!, tokens: tokens),
              if (command.trailingLabel != null)
                Text(
                  command.trailingLabel!,
                  style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({required this.label, required this.tokens});

  final String label;
  final SyriusThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: tokens.border),
      ),
      child: Text(
        label,
        style: tokens.monoStyle(fontSize: 10.5, color: tokens.textSecondary),
      ),
    );
  }
}

class _FooterHint extends StatelessWidget {
  const _FooterHint({
    required this.keys,
    required this.label,
    required this.tokens,
  });

  final String keys;
  final String label;
  final SyriusThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _KeyCap(label: keys, tokens: tokens),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11.5, color: tokens.textMuted)),
      ],
    );
  }
}

/// Builds the default set of Quick Navigation commands for the wallet.
List<QuickNavCommand> buildDefaultQuickNavCommands({
  required BuildContext context,
  required Map<String, String> contacts,
}) {
  final List<QuickNavCommand> list = <QuickNavCommand>[
    QuickNavCommand(
      id: 'page_home',
      category: context.l10n.pages,
      title: context.l10n.home,
      icon: Icons.home_outlined,
      shortcutHint: 'Ctrl 1',
      tab: Tabs.dashboard,
    ),
    QuickNavCommand(
      id: 'page_transfer',
      category: context.l10n.pages,
      title: context.l10n.transfer,
      subtitle:
          '${context.l10n.send} · ${context.l10n.receive} · '
          '${context.l10n.zap}',
      icon: Icons.send_outlined,
      shortcutHint: 'Ctrl 2',
      tab: Tabs.transfer,
    ),
    QuickNavCommand(
      id: 'page_staking',
      category: context.l10n.pages,
      title: context.l10n.staking,
      icon: Icons.donut_large_outlined,
      shortcutHint: 'Ctrl 3',
      tab: Tabs.staking,
    ),
    QuickNavCommand(
      id: 'page_nodes',
      category: context.l10n.pages,
      title: context.l10n.nodes,
      subtitle: '${context.l10n.pillars} · ${context.l10n.sentinels}',
      icon: Icons.layers_outlined,
      shortcutHint: 'Ctrl 4',
      tab: Tabs.pillars,
    ),
    QuickNavCommand(
      id: 'page_plasma',
      category: context.l10n.pages,
      title: context.l10n.plasma,
      icon: Icons.bolt_outlined,
      shortcutHint: 'Ctrl 5',
      tab: Tabs.plasma,
    ),
    QuickNavCommand(
      id: 'page_tokens',
      category: context.l10n.pages,
      title: context.l10n.tokens,
      icon: Icons.adjust_outlined,
      shortcutHint: 'Ctrl 6',
      tab: Tabs.tokens,
    ),
    QuickNavCommand(
      id: 'page_swap',
      category: context.l10n.pages,
      title: context.l10n.swap,
      icon: Icons.swap_horiz_rounded,
      shortcutHint: 'Ctrl 7',
      tab: Tabs.p2pSwap,
    ),
    QuickNavCommand(
      id: 'page_accelerator',
      category: context.l10n.pages,
      title: context.l10n.accelerator,
      icon: Icons.rocket_launch_outlined,
      shortcutHint: 'Ctrl 8',
      tab: Tabs.accelerator,
    ),
    QuickNavCommand(
      id: 'page_settings',
      category: context.l10n.pages,
      title: context.l10n.settings,
      icon: Icons.settings_outlined,
      tab: Tabs.settings,
    ),
    QuickNavCommand(
      id: 'action_delegate',
      category: context.l10n.actionsLabel,
      title: 'Delegate to a pillar',
      icon: Icons.layers_outlined,
      tab: Tabs.pillars,
    ),
    QuickNavCommand(
      id: 'action_fuse',
      category: context.l10n.actionsLabel,
      title: context.l10n.fusePlasmaTitle,
      icon: Icons.bolt_outlined,
      tab: Tabs.plasma,
    ),
    QuickNavCommand(
      id: 'action_toggle_privacy',
      category: context.l10n.actionsLabel,
      title: context.l10n.hideBalances,
      icon: Icons.visibility_off_outlined,
    ),
    QuickNavCommand(
      id: 'action_lock',
      category: context.l10n.actionsLabel,
      title: context.l10n.lock,
      icon: Icons.lock_outline_rounded,
      shortcutHint: 'Ctrl L',
      tab: Tabs.lock,
    ),
  ];

  // Add contacts & saved addresses for quick Send jump.
  for (final MapEntry<String, String> entry in contacts.entries) {
    final String addr = entry.key;
    final String shortAddr = addr.length > 14
        ? '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}'
        : addr;
    list.add(
      QuickNavCommand(
        id: 'addr_$addr',
        category: context.l10n.addresses,
        title: entry.value,
        subtitle: shortAddr,
        icon: Icons.bookmark_border_rounded,
        trailingLabel: 'Send to',
        tab: Tabs.transfer,
        address: addr,
      ),
    );
  }
  for (final String? raw in kDefaultAddressList) {
    if (raw == null || contacts.containsKey(raw)) {
      continue;
    }
    final String label = kAddressLabelMap[raw] ?? raw;
    final String shortAddr = raw.length > 14
        ? '${raw.substring(0, 6)}...${raw.substring(raw.length - 4)}'
        : raw;
    list.add(
      QuickNavCommand(
        id: 'wallet_addr_$raw',
        category: context.l10n.addresses,
        title: label,
        subtitle: shortAddr,
        icon: Icons.account_balance_wallet_outlined,
        trailingLabel: 'Send to',
        tab: Tabs.transfer,
        address: raw,
      ),
    );
  }

  return list;
}
