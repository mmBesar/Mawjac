import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/bidi.dart';
import '../../core/theme.dart';
import '../../data/mpv_runtime.dart';
import '../../l10n/languages.dart';
import '../../l10n/player_strings.dart';
import '../../l10n/strings.dart';

/// Audio and subtitle choices of the channel playing in the external mpv
/// window, read from and written to mpv over its control socket.
Future<void> showMpvTrackSheet(BuildContext context, MpvSession session) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => _MpvTrackSheet(session: session),
  );
}

class _MpvTrack {
  const _MpvTrack({
    required this.id,
    required this.type,
    required this.selected,
    this.language,
    this.title,
    this.codec,
  });

  final int id;
  final String type;
  final bool selected;
  final String? language;
  final String? title;
  final String? codec;
}

class _MpvTrackSheet extends StatefulWidget {
  const _MpvTrackSheet({required this.session});

  final MpvSession session;

  @override
  State<_MpvTrackSheet> createState() => _MpvTrackSheetState();
}

class _MpvTrackSheetState extends State<_MpvTrackSheet> {
  List<_MpvTrack>? _tracks;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    List<_MpvTrack> tracks = const <_MpvTrack>[];
    try {
      final raw = await widget.session.property('track-list');
      if (raw is List) {
        tracks = <_MpvTrack>[
          for (final entry in raw)
            if (entry is Map && entry['id'] is int)
              _MpvTrack(
                id: entry['id'] as int,
                type: '${entry['type']}',
                selected: entry['selected'] == true,
                language: entry['lang'] as String?,
                title: entry['title'] as String?,
                codec: entry['codec'] as String?,
              ),
        ];
      }
    } catch (_) {
      // An unreachable socket simply shows the empty state.
    }
    if (mounted) {
      setState(() => _tracks = tracks);
    }
  }

  Future<void> _choose(String type, int? id) async {
    final property = type == 'audio' ? 'aid' : 'sid';
    await widget.session.command(
      <Object>['set_property', property, id ?? 'no'],
    );
    await _load();
  }

  String _label(BuildContext context, _MpvTrack track, int index) {
    final strings = context.strings;
    final name = languageName(track.language, arabic: strings.isArabic);
    final extra = <String>[
      if (track.title != null &&
          track.title!.trim().isNotEmpty &&
          track.title!.trim() != name)
        track.title!.trim(),
      if (track.codec != null && track.codec!.trim().isNotEmpty)
        track.codec!.trim().toUpperCase(),
    ].join(' · ');
    final first = name.isNotEmpty ? name : strings.trackNumber(index + 1);
    return extra.isEmpty ? first : '$first · $extra';
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final colors = context.mawjColors;
    final theme = Theme.of(context);
    final tracks = _tracks;
    if (tracks == null) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final audio = tracks.where((t) => t.type == 'audio').toList();
    final subs = tracks.where((t) => t.type == 'sub').toList();

    Widget section(String title, List<_MpvTrack> list, String type) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.subtext0,
              ),
            ),
          ),
          if (type == 'sub')
            ListTile(
              dense: true,
              leading: Icon(
                subs.any((t) => t.selected)
                    ? Icons.radio_button_unchecked_rounded
                    : Icons.radio_button_checked_rounded,
                color: colors.accent,
              ),
              title: Text(strings.subtitlesOff),
              onTap: () => unawaited(_choose(type, null)),
            ),
          if (list.isEmpty && type == 'audio')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(strings.noTracks),
            ),
          for (var i = 0; i < list.length; i++)
            ListTile(
              dense: true,
              leading: Icon(
                list[i].selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: list[i].selected ? colors.accent : colors.subtext0,
              ),
              title: BidiText(_label(context, list[i], i)),
              onTap: () => unawaited(_choose(type, list[i].id)),
            ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          section(strings.audioTracks, audio, 'audio'),
          section(strings.subtitleTracks, subs, 'sub'),
        ],
      ),
    );
  }
}
