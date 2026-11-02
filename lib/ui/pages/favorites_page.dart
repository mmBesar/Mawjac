import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/platform.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../player_page.dart';
import '../widgets/channel_row.dart';
import '../widgets/channel_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_search.dart';
import '../widgets/programme_hit_tile.dart';
import 'channel_guide_page.dart';

/// Favorites on their own page, with what was watched last underneath.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key, this.searchRequests});

  /// Each change opens the search field (Ctrl+F).
  final ValueListenable<int>? searchRequests;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final PageSearch _search = PageSearch();

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
    widget.searchRequests?.addListener(_search.open);
  }

  @override
  void dispose() {
    widget.searchRequests?.removeListener(_search.open);
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = context.strings;
    final colors = context.mawjColors;
    final theme = Theme.of(context);
    final allowInsecure = state.activeSource?.allowInsecureCerts ?? false;
    final searching = _search.isSearching;
    final allFavorites = state.favorites;
    final favoriteIds = allFavorites.map((channel) => channel.id).toSet();
    // Searching here means searching your favorites: their names, and what
    // is on them.
    final matching = searching
        ? state.searchChannels(_search.query).map((c) => c.id).toSet()
        : const <String>{};
    final favorites = searching
        ? allFavorites
            .where((channel) => matching.contains(channel.id))
            .toList(growable: false)
        : allFavorites;
    final hits = searching
        ? state
            .searchProgrammes(_search.query, limit: 400)
            .where((hit) => favoriteIds.contains(hit.channel.id))
            .take(60)
            .toList(growable: false)
        : const <ProgrammeHit>[];
    final recents = searching
        ? const <Channel>[]
        : state.recents
            .where((channel) => !favoriteIds.contains(channel.id))
            .toList(growable: false);

    Widget item(Channel channel) {
      final programme = state.epg.nowFor(channel, state.now);
      final next = state.epg.nextFor(channel, state.now);
      return ChannelRow(
        channel: channel,
        programme: programme,
        next: next,
        now: state.now,
        allowInsecure: allowInsecure,
        favorite: state.isFavorite(channel),
        onTap: () => openPlayer(context, channel),
        onOpenGuide: () => ChannelGuidePage.open(context, channel),
        onToggleFavorite: () => unawaited(state.toggleFavorite(channel)),
      );
    }

    Widget section(String title, List<Channel> channels) {
      return SliverMainAxisGroup(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.subtext0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (kIsDesktop)
            SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: kChannelTileHeight,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return ChannelTile(
                  channel: channel,
                  programme: state.epg.nowFor(channel, state.now),
                  next: state.epg.nextFor(channel, state.now),
                  now: state.now,
                  allowInsecure: allowInsecure,
                  favorite: state.isFavorite(channel),
                  onPlay: () => openPlayer(context, channel),
                  onOpenGuide: () => ChannelGuidePage.open(context, channel),
                  onToggleFavorite: () =>
                      unawaited(state.toggleFavorite(channel)),
                );
              },
            )
          else
            SliverList.separated(
              itemCount: channels.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => item(channels[index]),
            ),
        ],
      );
    }

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      strings.favorites,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  PageSearchButton(search: _search),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: PageSearchField(search: _search, hint: strings.searchHint),
          ),
          if (searching && favorites.isEmpty && hits.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: strings.noResultsTitle,
                body: strings.noResultsBody(_search.query),
              ),
            )
          else if (allFavorites.isEmpty && recents.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.star_outline_rounded,
                title: strings.noFavorites,
                body: strings.noFavoritesBody,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverMainAxisGroup(
                slivers: <Widget>[
                  if (favorites.isNotEmpty) section(strings.favorites, favorites),
                  if (recents.isNotEmpty)
                    section(strings.recentlyWatched, recents),
                  if (hits.isNotEmpty)
                    SliverMainAxisGroup(
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
                            child: Text(
                              strings.programmesLabel,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.subtext0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SliverList.builder(
                          itemCount: hits.length,
                          itemBuilder: (context, index) => ProgrammeHitTile(
                            hit: hits[index],
                            now: state.now,
                            use24: state.settings.use24HourTime,
                            allowInsecure: allowInsecure,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
