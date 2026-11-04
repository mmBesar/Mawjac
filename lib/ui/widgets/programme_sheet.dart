import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/bidi.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../player_page.dart';
import 'channel_logo.dart';
import 'programme_poster.dart';
import 'wave.dart';

/// Details of one programme, with a way to watch its channel.
Future<void> showProgrammeSheet(
  BuildContext context, {
  required Channel channel,
  required Programme programme,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (sheetContext) {
      return _ProgrammeSheet(channel: channel, programme: programme);
    },
  );
}

class _ProgrammeSheet extends StatelessWidget {
  const _ProgrammeSheet({required this.channel, required this.programme});

  final Channel channel;
  final Programme programme;

  /// Original date, length, rating and the repeat marker, in that order.
  List<String> _facts(AppStrings strings) {
    final length = programme.lengthSeconds;
    return <String>[
      if (programme.date != null) programme.date!,
      if (length != null) strings.lengthMinutes((length / 60).round()),
      if (programme.rating != null) programme.rating!,
      if (programme.previouslyShown) strings.repeatShowing,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = context.strings;
    final colors = context.mawjColors;
    final theme = Theme.of(context);
    final now = state.now;
    final live = programme.isLiveAt(now);
    final upcoming = programme.start.isAfter(now);
    final use24 = state.settings.use24HourTime;
    final allowInsecure = state.activeSource?.allowInsecureCerts ?? false;
    final favorite = state.isFavorite(channel);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (programme.iconUrl != null) ...<Widget>[
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return ProgrammePoster(
                  programme: programme,
                  allowInsecure: allowInsecure,
                  width: width,
                  height: (width * 9 / 16).clamp(120.0, 260.0).toDouble(),
                  radius: 18,
                  fit: BoxFit.contain,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    BidiText(
                      programme.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (programme.subtitleLine != null) ...<Widget>[
                      const SizedBox(height: 4),
                      BidiText(
                        programme.subtitleLine!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.subtext0,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    BidiText(
                      '${strings.formatDate(programme.start)} · '
                      '${strings.formatRange(programme.start, programme.stop, use24HourTime: use24)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.subtext1,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    if (_facts(strings).isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      BidiText(
                        _facts(strings).join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.overlay1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (live) ...<Widget>[
            WaveProgress(
              progress: programme.progressAt(now),
              color: colors.accent,
              trackColor: colors.surface2,
              height: 18,
              animate: true,
            ),
            const SizedBox(height: 4),
            Text(
              strings.minutesLeft(
                programme.stop.difference(now).inMinutes.clamp(0, 9999).toInt(),
              ),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
          ] else if (upcoming) ...<Widget>[
            Text(
              strings.startsIn(
                programme.start.difference(now).inMinutes.clamp(0, 99999).toInt(),
              ),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.subtext0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (programme.description != null)
            BidiText(
              programme.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.subtext1,
                height: 1.6,
              ),
            )
          else
            Text(
              strings.noDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.overlay0,
                fontStyle: FontStyle.italic,
              ),
            ),
          if (programme.categories.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final category in programme.categories)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface0,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: BidiText(
                      category,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.subtext0,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (programme.keywords.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final keyword in programme.keywords)
                  BidiText(
                    '#$keyword',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.overlay1,
                    ),
                  ),
              ],
            ),
          ],
          for (final role in const <String>[
            'director',
            'writer',
            'presenter',
            'producer',
            'actor',
            'guest',
          ])
            if (programme.creditsOf(role).isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                strings.creditRole(role),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.subtext0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              BidiText(
                programme
                    .creditsOf(role)
                    .map(
                      (credit) => credit.character == null
                          ? credit.name
                          : '${credit.name} (${credit.character})',
                    )
                    .join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.subtext1,
                  height: 1.5,
                ),
              ),
            ],
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              ChannelLogo(
                channel: channel,
                allowInsecure: allowInsecure,
                size: 44,
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BidiText(
                  channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip:
                    favorite ? strings.removeFavorite : strings.addFavorite,
                onPressed: () => state.toggleFavorite(channel),
                icon: Icon(
                  favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: favorite ? colors.accent : colors.subtext0,
                ),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  openPlayer(context, channel);
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(live ? strings.watchLive : strings.watchChannel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
