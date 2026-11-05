import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/bidi.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../l10n/player_strings.dart';
import '../../l10n/strings.dart';
import 'channel_logo.dart';
import 'stb_osd.dart';

/// The channel's own guide over the picture: what is on and what follows,
/// with the details of the highlighted programme.
class StbEpgPanel extends StatefulWidget {
  const StbEpgPanel({
    super.key,
    required this.channel,
    required this.programmes,
    required this.now,
    required this.use24,
    required this.allowInsecure,
    required this.onClose,
  });

  final Channel channel;

  /// In time order; the caller drops what ended long ago.
  final List<Programme> programmes;
  final DateTime now;
  final bool use24;
  final bool allowInsecure;
  final VoidCallback onClose;

  @override
  State<StbEpgPanel> createState() => _StbEpgPanelState();
}

class _StbEpgPanelState extends State<StbEpgPanel> {
  static const double _rowHeight = 64;

  final FocusNode _focus = FocusNode(debugLabel: 'stb-epg');
  final ScrollController _scroll = ScrollController();
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    final live = widget.programmes.indexWhere((p) => p.isLiveAt(widget.now));
    _selected = live < 0 ? 0 : live;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      if (_scroll.hasClients) {
        final viewport = _scroll.position.viewportDimension;
        final target = _selected * _rowHeight - (viewport - _rowHeight) / 3;
        _scroll.jumpTo(
          target.clamp(0.0, _scroll.position.maxScrollExtent).toDouble(),
        );
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Programme? get _current =>
      widget.programmes.isEmpty ? null : widget.programmes[_selected];

  void _move(int delta) {
    if (widget.programmes.isEmpty) {
      return;
    }
    setState(() {
      _selected = (_selected + delta).clamp(0, widget.programmes.length - 1);
    });
    if (!_scroll.hasClients) {
      return;
    }
    final position = _scroll.position;
    final top = _selected * _rowHeight;
    if (top < position.pixels) {
      unawaited(_scroll.animateTo(
        top,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
      ));
    } else if (top + _rowHeight > position.pixels + position.viewportDimension) {
      unawaited(_scroll.animateTo(
        top + _rowHeight - position.viewportDimension,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
      ));
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyG) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _move(6);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _move(-6);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final colors = context.mawjColors;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 720;
    final programme = _current;

    final panel = Container(
      width: compact ? double.infinity : 560,
      height: compact ? size.height * 0.78 : null,
      margin: compact
          ? const EdgeInsets.fromLTRB(8, 0, 8, 8)
          : const EdgeInsets.fromLTRB(20, 56, 20, 20),
      decoration: stbPanelDecoration(colors.accent),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: <Widget>[
                ChannelLogo(
                  channel: widget.channel,
                  allowInsecure: widget.allowInsecure,
                  size: 40,
                  radius: 10,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.stbEpg.toUpperCase(),
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      BidiText(
                        widget.channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: strings.close,
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: widget.programmes.isEmpty
                ? Center(
                    child: Text(
                      strings.noGuide,
                      style: const TextStyle(color: Colors.white60, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    itemExtent: _rowHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: widget.programmes.length,
                    itemBuilder: (context, index) {
                      final item = widget.programmes[index];
                      return _EpgRow(
                        programme: item,
                        now: widget.now,
                        use24: widget.use24,
                        selected: index == _selected,
                        onTap: () => setState(() => _selected = index),
                      );
                    },
                  ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.10)),
          Expanded(
            flex: 5,
            child: programme == null
                ? const SizedBox.shrink()
                : _Details(
                    programme: programme,
                    now: widget.now,
                    use24: widget.use24,
                  ),
          ),
          if (!compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                strings.stbEpgHint,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11.5,
                ),
              ),
            ),
        ],
      ),
    );

    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: const ColoredBox(color: Color(0x59000000)),
            ),
          ),
          Align(
            alignment: compact
                ? Alignment.bottomCenter
                : AlignmentDirectional.centerEnd,
            child: panel,
          ),
        ],
      ),
    );
  }
}

class _EpgRow extends StatelessWidget {
  const _EpgRow({
    required this.programme,
    required this.now,
    required this.use24,
    required this.selected,
    required this.onTap,
  });

  final Programme programme;
  final DateTime now;
  final bool use24;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mawjColors;
    final strings = context.strings;
    final live = programme.isLiveAt(now);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.accent : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 82,
              child: Text(
                strings.formatTime(programme.start, use24HourTime: use24),
                style: TextStyle(
                  color: live ? colors.accent : Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  BidiText(
                    programme.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (live) ...<Widget>[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: programme.progressAt(now),
                        minHeight: 3,
                        color: colors.accent,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ] else if ((programme.subTitle ?? '').isNotEmpty)
                    BidiText(
                      programme.subTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.programme,
    required this.now,
    required this.use24,
  });

  final Programme programme;
  final DateTime now;
  final bool use24;

  List<String> _facts(AppStrings strings) {
    final length = programme.lengthSeconds;
    return <String>[
      if (programme.date != null) programme.date!,
      if (length != null) strings.lengthMinutes((length / 60).round()),
      if (programme.rating != null) programme.rating!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final colors = context.mawjColors;
    final minutes = programme.stop.difference(programme.start).inMinutes;
    final facts = _facts(strings);
    final subtitle = programme.subtitleLine;
    final badges = <String>[
      if (programme.previouslyShown) strings.repeatShowing,
      ...programme.categories.take(4),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          BidiText(
            programme.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: BidiText(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 15,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            '${strings.formatDate(programme.start)} · '
            '${strings.formatRange(programme.start, programme.stop, use24HourTime: use24)}'
            ' · $minutes ${strings.minutesShort}',
            style: TextStyle(
              color: colors.accent,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (badges.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final badge in badges)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if ((programme.description ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            BidiText(
              programme.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
          ],
          if (facts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            BidiText(
              facts.join(' · '),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12.5,
              ),
            ),
          ],
          for (final role in const <String>[
            'director',
            'writer',
            'presenter',
            'actor',
            'guest',
          ])
            if (programme.creditsOf(role).isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              BidiText(
                '${strings.creditRole(role)}: '
                '${programme.creditsOf(role).map((c) => c.character == null ? c.name : '${c.name} (${c.character})').join(' · ')}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
        ],
      ),
    );
  }
}
