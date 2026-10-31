import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/bidi.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../player_page.dart';
import 'channel_guide_page.dart';
import '../widgets/channel_logo.dart';
import '../widgets/empty_state.dart';
import '../widgets/programme_sheet.dart';
import '../widgets/warnings_panel.dart';

/// A twelve-hour timeline. The channel column stays put while the programmes
/// scroll sideways, and both scroll up and down together.
class GuidePage extends StatefulWidget {
  const GuidePage({super.key, required this.onOpenSources});

  final VoidCallback onOpenSources;

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  static const double _pxPerMinute = 5;
  static const double _rowHeight = 72;
  static const double _channelWidth = 104;
  static const double _headerHeight = 40;
  static const int _spanMinutes = 12 * 60;
  static const double _bottomPadding = 110;

  final ScrollController _horizontal = ScrollController();
  final ScrollController _leftVertical = ScrollController();
  final ScrollController _rightVertical = ScrollController();

  bool _syncing = false;
  bool _favoritesOnly = false;
  bool _scrolledToNow = false;
  late DateTime _windowStart;

  @override
  void initState() {
    super.initState();
    _windowStart = _windowStartFor(DateTime.now());
    _leftVertical.addListener(() => _sync(_leftVertical, _rightVertical));
    _rightVertical.addListener(() => _sync(_rightVertical, _leftVertical));
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _leftVertical.dispose();
    _rightVertical.dispose();
    super.dispose();
  }

  /// One hour before the last half hour, so "now" has some history on its left.
  static DateTime _windowStartFor(DateTime now) {
    final floored = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute >= 30 ? 30 : 0,
    );
    return floored.subtract(const Duration(hours: 1));
  }

  void _sync(ScrollController from, ScrollController to) {
    if (_syncing || !from.hasClients || !to.hasClients) {
      return;
    }
    final target = from.offset
        .clamp(to.position.minScrollExtent, to.position.maxScrollExtent)
        .toDouble();
    if ((to.offset - target).abs() < 0.5) {
      return;
    }
    _syncing = true;
    to.jumpTo(target);
    _syncing = false;
  }

  double _nowOffset(DateTime now) {
    final minutes = now.difference(_windowStart).inSeconds / 60;
    return minutes * _pxPerMinute;
  }

  void _scrollToNow(DateTime now, {bool animate = false}) {
    if (!_horizontal.hasClients) {
      return;
    }
    final target = (_nowOffset(now) - 64)
        .clamp(0.0, _horizontal.position.maxScrollExtent)
        .toDouble();
    if (animate) {
      _horizontal.animateTo(
        target,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _horizontal.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = context.strings;
    final colors = context.mawjColors;
    final theme = Theme.of(context);

    if (state.sources.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_month_rounded,
        title: strings.noSources,
        body: strings.guideNoChannels,
        actionLabel: strings.addSource,
        onAction: widget.onOpenSources,
      );
    }

    // Roll the window forward when the app has been open for most of it.
    if (state.now.isAfter(
      _windowStart.add(const Duration(minutes: _spanMinutes - 90)),
    )) {
      _windowStart = _windowStartFor(state.now);
      _scrolledToNow = false;
    }

    final channels = _favoritesOnly && state.favorites.isNotEmpty
        ? state.favorites
        : state.channels;
    final windowEnd = _windowStart.add(const Duration(minutes: _spanMinutes));
    final use24 = state.settings.use24HourTime;
    final allowInsecure = state.activeSource?.allowInsecureCerts ?? false;
    const gridWidth = _spanMinutes * _pxPerMinute;
    final nowX = _nowOffset(state.now);

    if (!_scrolledToNow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_horizontal.hasClients || _scrolledToNow) {
          return;
        }
        _scrolledToNow = true;
        _scrollToNow(state.now);
      });
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    strings.guide,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: strings.guideFavoritesOnly,
                  isSelected: _favoritesOnly,
                  onPressed: state.favorites.isEmpty
                      ? null
                      : () => setState(() => _favoritesOnly = !_favoritesOnly),
                  icon: const Icon(Icons.star_outline_rounded),
                  selectedIcon: Icon(Icons.star_rounded, color: colors.accent),
                ),
                const SizedBox(width: 4),
                FilledButton.tonalIcon(
                  onPressed: () => _scrollToNow(state.now, animate: true),
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(strings.guideNow),
                ),
              ],
            ),
          ),
          WarningsPanel(warnings: state.warnings),
          if (channels.isEmpty)
            Expanded(
              child: EmptyState(
                icon: Icons.calendar_month_rounded,
                title: strings.guideEmptyTitle,
                body: strings.guideNoChannels,
              ),
            )
          else
            Expanded(
              // Time always runs left to right, whatever the interface
              // language, so the timeline reads the same in Arabic.
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: _channelWidth,
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: _headerHeight),
                          Expanded(
                            child: ListView.builder(
                              controller: _leftVertical,
                              itemExtent: _rowHeight,
                              padding: const EdgeInsets.only(
                                bottom: _bottomPadding,
                              ),
                              itemCount: channels.length,
                              itemBuilder: (context, index) {
                                return _ChannelCell(
                                  channel: channels[index],
                                  allowInsecure: allowInsecure,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horizontal,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: gridWidth,
                          child: Column(
                            children: <Widget>[
                              _TimeHeader(
                                start: _windowStart,
                                use24: use24,
                                nowX: nowX,
                                height: _headerHeight,
                                pxPerMinute: _pxPerMinute,
                                spanMinutes: _spanMinutes,
                              ),
                              Expanded(
                                child: Stack(
                                  children: <Widget>[
                                    ListView.builder(
                                      controller: _rightVertical,
                                      itemExtent: _rowHeight,
                                      padding: const EdgeInsets.only(
                                        bottom: _bottomPadding,
                                      ),
                                      itemCount: channels.length,
                                      itemBuilder: (context, index) {
                                        return _buildRow(
                                          context,
                                          state,
                                          channels[index],
                                          windowEnd,
                                          use24,
                                        );
                                      },
                                    ),
                                    if (nowX > 0 && nowX < gridWidth)
                                      Positioned(
                                        left: nowX - 1,
                                        top: 0,
                                        bottom: 0,
                                        width: 2,
                                        child: IgnorePointer(
                                          child: ColoredBox(
                                            color: colors.accent.withValues(
                                              alpha: 0.85,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    AppState state,
    Channel channel,
    DateTime windowEnd,
    bool use24,
  ) {
    final colors = context.mawjColors;
    final strings = context.strings;
    final programmes = state.epg.forWindow(channel, _windowStart, windowEnd);
    final blocks = <Widget>[];
    for (final programme in programmes) {
      final startMinutes =
          programme.start.difference(_windowStart).inSeconds / 60;
      final stopMinutes =
          programme.stop.difference(_windowStart).inSeconds / 60;
      final left = math.max(0.0, startMinutes) * _pxPerMinute;
      final right =
          math.min(_spanMinutes.toDouble(), stopMinutes) * _pxPerMinute;
      final width = right - left - 3;
      if (width < 8) {
        continue;
      }
      blocks.add(
        Positioned(
          left: left,
          width: width,
          top: 6,
          bottom: 6,
          child: _Block(
            programme: programme,
            live: programme.isLiveAt(state.now),
            range: strings.formatRange(
              programme.start,
              programme.stop,
              use24HourTime: use24,
            ),
            onTap: () => showProgrammeSheet(
              context,
              channel: channel,
              programme: programme,
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.surface0.withValues(alpha: 0.5)),
        ),
      ),
      child: Stack(children: blocks),
    );
  }
}

class _TimeHeader extends StatelessWidget {
  const _TimeHeader({
    required this.start,
    required this.use24,
    required this.nowX,
    required this.height,
    required this.pxPerMinute,
    required this.spanMinutes,
  });

  final DateTime start;
  final bool use24;
  final double nowX;
  final double height;
  final double pxPerMinute;
  final int spanMinutes;

  @override
  Widget build(BuildContext context) {
    final colors = context.mawjColors;
    final theme = Theme.of(context);
    final strings = context.strings;
    return SizedBox(
      height: height,
      child: Stack(
        children: <Widget>[
          for (var slot = 0; slot < spanMinutes ~/ 30; slot++)
            Positioned(
              left: slot * 30 * pxPerMinute + 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  strings.formatTime(
                    start.add(Duration(minutes: slot * 30)),
                    use24HourTime: use24,
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: slot.isEven ? colors.subtext1 : colors.overlay1,
                    fontWeight: slot.isEven ? FontWeight.w700 : FontWeight.w500,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ),
          if (nowX > 0 && nowX < spanMinutes * pxPerMinute)
            Positioned(
              left: nowX - 5,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChannelCell extends StatelessWidget {
  const _ChannelCell({required this.channel, required this.allowInsecure});

  final Channel channel;
  final bool allowInsecure;

  @override
  Widget build(BuildContext context) {
    final colors = context.mawjColors;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => openPlayer(context, channel),
      onLongPress: () => ChannelGuidePage.open(context, channel),
      onSecondaryTap: () => ChannelGuidePage.open(context, channel),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.surface0.withValues(alpha: 0.5)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ChannelLogo(
                channel: channel,
                allowInsecure: allowInsecure,
                size: 34,
                radius: 10,
              ),
              const SizedBox(height: 4),
              BidiText(
                channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.subtext1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.programme,
    required this.live,
    required this.range,
    required this.onTap,
  });

  final Programme programme;
  final bool live;
  final String range;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mawjColors;
    final theme = Theme.of(context);
    return Material(
      color: live ? colors.accentSoft : colors.surface0.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: live
                ? Border.all(color: colors.accent.withValues(alpha: 0.7))
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 48) {
                return const SizedBox.shrink();
              }
              final roomy = constraints.maxWidth >= 120;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    BidiText(
                      programme.title,
                      maxLines: roomy ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: live ? colors.text : colors.subtext1,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (roomy)
                      Text(
                        range,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: live ? colors.accent : colors.overlay1,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
