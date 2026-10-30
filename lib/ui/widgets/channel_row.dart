import 'package:flutter/material.dart';

import '../../core/bidi.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import 'channel_logo.dart';
import 'wave.dart';

/// Fixed height of [ChannelRow], so lists can use a fixed item extent.
const double kChannelRowHeight = 88;

/// One channel in a list: logo, name, what is on, and the wave showing how far
/// into it the channel is.
class ChannelRow extends StatelessWidget {
  const ChannelRow({
    super.key,
    required this.channel,
    required this.programme,
    required this.now,
    required this.allowInsecure,
    required this.favorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final Channel channel;
  final Programme? programme;
  final DateTime now;
  final bool allowInsecure;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = context.mawjColors;
    final theme = Theme.of(context);
    final strings = context.strings;
    final current = programme;

    return SizedBox(
      height: kChannelRowHeight,
      child: Material(
        color: colors.surface0.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
            child: Row(
              children: <Widget>[
                ChannelLogo(
                  channel: channel,
                  allowInsecure: allowInsecure,
                  size: 60,
                  radius: 16,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            channel.displayNumber,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.accent,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (current != null) ...<Widget>[
                        BidiText(
                          current.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.subtext1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        WaveProgress(
                          progress: current.progressAt(now),
                          color: colors.accent,
                          trackColor: colors.surface2,
                          height: 14,
                        ),
                      ] else
                        BidiText(
                          channel.group ?? strings.noProgrammeInfo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.overlay1,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: favorite
                      ? strings.removeFavorite
                      : strings.addFavorite,
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: favorite ? colors.accent : colors.overlay1,
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
