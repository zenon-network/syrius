import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';

/// Collapsible left navigation rail matching Screens 01 and 02.
class SyriusNavigationRail extends StatelessWidget {
  /// Creates a [SyriusNavigationRail].
  const SyriusNavigationRail({
    required this.activeTab,
    required this.isExpanded,
    required this.hasUnreadNotifications,
    required this.isNotificationsOpen,
    required this.onToggleExpanded,
    required this.onTabSelected,
    required this.onNotificationsPressed,
    required this.onLockPressed,
    super.key,
  });

  /// Currently active navigation tab.
  final Tabs activeTab;

  /// Whether labels are shown alongside icons (`184px` vs `56px`).
  final bool isExpanded;

  /// Displays a magenta badge dot on the Notifications bell when true.
  final bool hasUnreadNotifications;

  /// Highlights the Notifications item when the slide-over drawer is open.
  final bool isNotificationsOpen;

  /// Toggles collapsed/expanded rail state.
  final VoidCallback onToggleExpanded;

  /// Called when the user selects a navigation destination.
  final ValueChanged<Tabs> onTabSelected;

  /// Called when the user clicks the Notifications bell.
  final VoidCallback onNotificationsPressed;

  /// Called when the user clicks the Lock action.
  final VoidCallback onLockPressed;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final bool isNodesSelected =
        activeTab == Tabs.pillars || activeTab == Tabs.sentinels;
    final bool isSettingsSelected =
        activeTab == Tabs.settings ||
        activeTab == Tabs.help ||
        activeTab == Tabs.walletConnect;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: isExpanded ? 184 : 56,
      padding: EdgeInsets.fromLTRB(
        isExpanded ? 10 : 8,
        2,
        isExpanded ? 10 : 8,
        12,
      ),
      child: Column(
        crossAxisAlignment: isExpanded
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: <Widget>[
          _RailExpandButton(isExpanded: isExpanded, onTap: onToggleExpanded),
          const SizedBox(height: 6),
          _RailItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: context.l10n.home,
            selected: activeTab == Tabs.dashboard && !isNotificationsOpen,
            expanded: isExpanded,
            onTap: () => onTabSelected(Tabs.dashboard),
          ),
          _RailItem(
            icon: Icons.send_outlined,
            activeIcon: Icons.send_rounded,
            label: context.l10n.transfer,
            selected: activeTab == Tabs.transfer && !isNotificationsOpen,
            expanded: isExpanded,
            onTap: () => onTabSelected(Tabs.transfer),
          ),
          _RailItem(
            icon: MaterialCommunityIcons.chart_donut,
            activeIcon: MaterialCommunityIcons.chart_donut,
            label: context.l10n.staking,
            selected: activeTab == Tabs.staking && !isNotificationsOpen,
            expanded: isExpanded,
            onTap: () => onTabSelected(Tabs.staking),
          ),
          _RailItem(
            icon: Icons.layers_outlined,
            activeIcon: Icons.layers_rounded,
            label: context.l10n.nodes,
            selected: isNodesSelected && !isNotificationsOpen,
            expanded: isExpanded,
            onTap: () => onTabSelected(Tabs.pillars),
          ),
          _RailItem(
            icon: Icons.bolt_outlined,
            activeIcon: Icons.bolt_rounded,
            label: context.l10n.plasma,
            selected: activeTab == Tabs.plasma && !isNotificationsOpen,
            expanded: isExpanded,
            onTap: () => onTabSelected(Tabs.plasma),
          ),
          _RailItem(
            icon: Icons.adjust_outlined,
            activeIcon: Icons.adjust_rounded,
            label: context.l10n.tokens,
            selected: activeTab == Tabs.tokens && !isNotificationsOpen,
            expanded: isExpanded,
            onTap: () => onTabSelected(Tabs.tokens),
          ),
          _RailItem(
            icon: Icons.swap_horiz_rounded,
            activeIcon: Icons.swap_horiz_rounded,
            label: context.l10n.swap,
            selected: activeTab == Tabs.p2pSwap && !isNotificationsOpen,
            expanded: isExpanded,
            onTap: () => onTabSelected(Tabs.p2pSwap),
          ),
          _RailItem(
            icon: MaterialCommunityIcons.rocket_outline,
            activeIcon: MaterialCommunityIcons.rocket,
            label: context.l10n.accelerator,
            selected: activeTab == Tabs.accelerator && !isNotificationsOpen,
            expanded: isExpanded,
            onTap: () => onTabSelected(Tabs.accelerator),
          ),
          const Spacer(),
          _RailItem(
            icon: Icons.notifications_none_outlined,
            activeIcon: Icons.notifications_rounded,
            label: context.l10n.notifications,
            selected: isNotificationsOpen || activeTab == Tabs.notifications,
            expanded: isExpanded,
            showBadgeDot: hasUnreadNotifications,
            badgeColor: tokens.ztsMagenta,
            onTap: onNotificationsPressed,
          ),
          _RailItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: context.l10n.settings,
            selected: isSettingsSelected && !isNotificationsOpen,
            expanded: isExpanded,
            onTap: () => onTabSelected(Tabs.settings),
          ),
          _RailItem(
            icon: Icons.lock_outline_rounded,
            activeIcon: Icons.lock_rounded,
            label: context.l10n.lock,
            selected: activeTab == Tabs.lock,
            expanded: isExpanded,
            onTap: onLockPressed,
          ),
        ],
      ),
    );
  }
}

class _RailExpandButton extends StatelessWidget {
  const _RailExpandButton({required this.isExpanded, required this.onTap});

  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Align(
      alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
      child: Tooltip(
        message: isExpanded ? context.l10n.icons : context.l10n.labels,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 34,
            height: 30,
            child: Icon(
              isExpanded ? Icons.chevron_left : Icons.chevron_right,
              size: 17,
              color: tokens.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  const _RailItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
    this.showBadgeDot = false,
    this.badgeColor,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;
  final bool showBadgeDot;
  final Color? badgeColor;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final Color iconColor = widget.selected
        ? tokens.znnGreen
        : _hovered
        ? tokens.textPrimary
        : tokens.textSecondary;
    final Color bgColor = widget.selected
        ? tokens.railActiveSurface
        : _hovered
        ? tokens.surfaceElevated.withValues(alpha: 0.5)
        : Colors.transparent;

    final Widget iconWidget = Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(
          widget.selected ? widget.activeIcon : widget.icon,
          size: 19,
          color: iconColor,
        ),
        if (widget.showBadgeDot)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: widget.badgeColor ?? tokens.ztsMagenta,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );

    final Widget item = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 38,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: widget.expanded ? 12 : 0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: widget.selected
                ? Border.all(color: tokens.border)
                : Border.all(color: Colors.transparent),
          ),
          child: widget.expanded
              ? Row(
                  children: <Widget>[
                    iconWidget,
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: widget.selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: widget.selected
                              ? tokens.textPrimary
                              : tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(child: iconWidget),
        ),
      ),
    );

    if (widget.expanded) {
      return item;
    }

    return Tooltip(
      message: widget.label,
      waitDuration: const Duration(milliseconds: 350),
      child: item,
    );
  }
}
