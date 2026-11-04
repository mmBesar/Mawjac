import 'package:flutter/material.dart';

import '../../core/bidi.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import 'channel_logo.dart';
import 'programme_poster.dart';
import 'programme_sheet.dart';

/// A programme found by a search: artwork (or the channel logo), title,
/// sub-title, and which channel airs it when.
class ProgrammeHitTile extends StatelessWidget {
  const ProgrammeHitTile({
    super.key,
    required this.hit,
    required this.now,
    required this.use24,
    required this.allowInsecure,
  });

  final ProgrammeHit hit;
  final DateTime now;
  final bool use24;
  final bool allowInsecure;

  @override
  Widget build(BuildContext context) {
    final colors = context.mawjColors;
    final theme = Theme.of(context);
    final strings = context.strings;
    final programme = hit.programme;
    final live = programme.isLiveAt(now);
    final when = live
        ? strings.now
        : '${strings.formatDate(programme.start)} '
            '${strings.formatTime(programme.start, use24HourTime: use24)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surface0.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showProgrammeSheet(
            context,
            channel: hit.channel,
            programme: programme,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                if (programme.iconUrl != null &&
                    programme.iconUrl!.trim().isNotEmpty)
                  ProgrammePoster(
                    programme: programme,
                    allowInsecure: allowInsecure,
                    width: 128,
                    height: 72,
                    radius: 12,
                  )
                else
                  ChannelLogo(
                    channel: hit.channel,
                    allowInsecure: allowInsecure,
                    size: 56,
                    radius: 14,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      BidiText(
                        programme.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (programme.subtitleLine != null)
                        BidiText(
                          programme.subtitleLine!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.subtext1,
                          ),
                        ),
                      const SizedBox(height: 2),
                      BidiText(
                        '${hit.channel.name} · $when',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: live ? colors.accent : colors.subtext0,
                          fontWeight: live ? FontWeight.w700 : FontWeight.w400,
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
    );
  }
}
