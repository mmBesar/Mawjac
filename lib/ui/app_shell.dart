import 'package:flutter/material.dart';

import '../core/bidi.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import 'pages/guide_page.dart';
import 'pages/search_page.dart';
import 'pages/settings_page.dart';
import 'pages/sources_page.dart';
import 'pages/watch_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _openSources() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: const SourcesPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final colors = context.mawjColors;

    final pages = <Widget>[
      WatchPage(onOpenSources: _openSources),
      GuidePage(onOpenSources: _openSources),
      const SearchPage(),
      SettingsPage(onOpenSources: _openSources),
    ];
    final labels = <String>[
      strings.watch,
      strings.guide,
      strings.search,
      strings.settings,
    ];
    const icons = <IconData>[
      Icons.live_tv_rounded,
      Icons.calendar_month_rounded,
      Icons.search_rounded,
      Icons.tune_rounded,
    ];

    final content = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // A faint glow in one corner: the only decoration on the screen.
        PositionedDirectional(
          top: -140,
          end: -100,
          child: IgnorePointer(
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    colors.accent.withValues(alpha: 0.14),
                    colors.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        IndexedStack(index: _index, children: pages),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          final extended = constraints.maxWidth >= 1280;
          return Scaffold(
            body: Row(
              children: <Widget>[
                NavigationRail(
                  extended: extended,
                  selectedIndex: _index,
                  backgroundColor: colors.mantle,
                  onDestinationSelected: (index) =>
                      setState(() => _index = index),
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/branding/mawjac_icon.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                  destinations: <NavigationRailDestination>[
                    for (var index = 0; index < labels.length; index++)
                      NavigationRailDestination(
                        icon: Icon(icons[index]),
                        selectedIcon: Icon(icons[index], color: colors.accent),
                        label: BidiText(labels[index]),
                      ),
                  ],
                ),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: <Widget>[
              Positioned.fill(child: content),
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.viewPaddingOf(context).bottom + 14,
                child: Center(
                  child: _FloatingNav(
                    labels: labels,
                    icons: icons,
                    selected: _index,
                    onSelected: (index) => setState(() => _index = index),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The phone navigation: a floating pill where only the selected item shows
/// its label.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.labels,
    required this.icons,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final List<IconData> icons;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.mawjColors;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surface0.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.surface1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var index = 0; index < labels.length; index++)
            _NavItem(
              label: labels[index],
              icon: icons[index],
              selected: index == selected,
              accent: colors.accent,
              onAccent: theme.colorScheme.onPrimary,
              idle: colors.subtext0,
              onTap: () => onSelected(index),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onAccent,
    required this.idle,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final Color onAccent;
  final Color idle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 14),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 24, color: selected ? onAccent : idle),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8),
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            color: onAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
