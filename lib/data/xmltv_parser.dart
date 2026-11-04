import 'package:xml/xml.dart';

import 'models.dart';

/// Parsed XMLTV output. [unmatchedChannels] counts XMLTV channels that could
/// not be tied to a playlist entry, which is useful for diagnostics.
class XmltvParseResult {
  const XmltvParseResult({
    required this.epg,
    required this.matchedChannels,
    required this.unmatchedChannels,
    required this.channelNames,
    this.report = '',
  });

  final EpgData epg;
  final int matchedChannels;
  final int unmatchedChannels;
  final Map<String, String> channelNames;

  /// Human-readable explanation of playlist channels that ended up without a
  /// guide and of XMLTV ids that matched nothing. Empty when all is well.
  final String report;
}

/// Parses XMLTV into [EpgData] keyed by Mawjac's internal channel ids.
///
/// Only programmes that overlap the visible window are kept. A typical
/// XMLTV file contains several days of data for dozens of channels, and
/// keeping all of it needlessly inflates memory on phones.
class XmltvParser {
  const XmltvParser({
    this.pastWindow = const Duration(hours: 12),
    this.futureWindow = const Duration(hours: 72),
  });

  /// How much history to retain. The guide can scroll back a little.
  final Duration pastWindow;

  /// How much upcoming programming to retain.
  final Duration futureWindow;

  XmltvParseResult parse(
    String content,
    List<Channel> channels, {
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toLocal();
    final document = XmlDocument.parse(content);
    final catalogue = _ChannelCatalogue(channels);

    final tv = document.findAllElements('tv').firstOrNull;
    if (tv == null) {
      return XmltvParseResult(
        epg: EpgData.empty(),
        matchedChannels: 0,
        unmatchedChannels: 0,
        channelNames: const <String, String>{},
      );
    }

    for (final element in tv.childElements) {
      if (element.name.local != 'channel') {
        continue;
      }
      final id = element.getAttribute('id')?.trim() ?? '';
      if (id.isEmpty) {
        continue;
      }
      final names = element
          .findAllElements('display-name')
          .map((node) => node.innerText.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      catalogue.register(id, names);
    }

    final windowStart = reference.subtract(pastWindow);
    final windowEnd = reference.add(futureWindow);
    final byChannel = <String, List<Programme>>{};
    final stats = <String, _DropStats>{};
    final orphanProgrammes = <String, int>{};

    for (final element in tv.childElements) {
      if (element.name.local != 'programme') {
        continue;
      }
      final xmltvChannel = element.getAttribute('channel')?.trim() ?? '';
      final internalId = catalogue.resolve(xmltvChannel);
      if (internalId == null) {
        orphanProgrammes.update(
          xmltvChannel,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        continue;
      }
      final stat = stats.putIfAbsent(internalId, _DropStats.new);
      stat.seen += 1;

      final start = parseXmltvTime(element.getAttribute('start'));
      final stop = parseXmltvTime(element.getAttribute('stop'));
      if (start == null || stop == null || !stop.isAfter(start)) {
        stat.badTime += 1;
        continue;
      }
      if (!stop.isAfter(windowStart) || !start.isBefore(windowEnd)) {
        stat.outsideWindow += 1;
        continue;
      }

      // Some servers publish filler or placeholder blocks without a title.
      // Dropping them leaves a hole in the guide, so fall back to the
      // sub-title or the first line of the description.
      var title = _firstText(element, 'title');
      if (title.isEmpty) {
        title = _optionalText(element, 'sub-title') ??
            _firstLine(_optionalText(element, 'desc')) ??
            '';
      }
      if (title.isEmpty) {
        stat.noTitle += 1;
        continue;
      }

      final categories = element
          .findAllElements('category')
          .map((node) => node.innerText.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      final artwork = _artwork(element);

      byChannel.putIfAbsent(internalId, () => <Programme>[]).add(
            Programme(
              channelId: internalId,
              start: start,
              stop: stop,
              title: title,
              subTitle: _optionalText(element, 'sub-title'),
              description: _optionalText(element, 'desc'),
              categories: categories,
              iconUrl: artwork.landscape,
              posterUrl: artwork.poster,
              episode: _episodeNumber(element),
              credits: _credits(element),
              date: _optionalText(element, 'date'),
              keywords: element
                  .findElements('keyword')
                  .map((node) => node.innerText.trim())
                  .where((value) => value.isNotEmpty)
                  .toList(growable: false),
              lengthSeconds: _lengthSeconds(element),
              rating: _rating(element),
              previouslyShown: element.findElements('previously-shown').isNotEmpty,
            ),
          );
    }

    for (final programmes in byChannel.values) {
      programmes.sort((a, b) => a.start.compareTo(b.start));
    }

    return XmltvParseResult(
      epg: EpgData.fromMap(byChannel),
      matchedChannels: byChannel.length,
      unmatchedChannels: catalogue.unmatched,
      channelNames: catalogue.names,
      report: _buildReport(channels, byChannel, stats, orphanProgrammes),
    );
  }

  static String? _firstLine(String? value) {
    if (value == null) {
      return null;
    }
    final line = value.split('\n').first.trim();
    if (line.isEmpty) {
      return null;
    }
    return line.length > 80 ? '${line.substring(0, 77)}...' : line;
  }

  static String _buildReport(
    List<Channel> channels,
    Map<String, List<Programme>> byChannel,
    Map<String, _DropStats> stats,
    Map<String, int> orphanProgrammes,
  ) {
    final lines = <String>[];
    for (final channel in channels) {
      if (byChannel[channel.id]?.isNotEmpty ?? false) {
        continue;
      }
      final stat = stats[channel.id];
      final why = stat == null
          ? 'no XMLTV programme is addressed to it '
              '(tvg-id="${channel.tvgId}", channel-id="${channel.channelId}")'
          : 'seen ${stat.seen}, bad time ${stat.badTime}, '
              'outside window ${stat.outsideWindow}, no title ${stat.noTitle}';
      lines.add('  ${channel.number} ${channel.name}: $why');
    }
    if (orphanProgrammes.isNotEmpty) {
      final shown = orphanProgrammes.entries
          .take(10)
          .map((entry) => '"${entry.key}" x${entry.value}')
          .join(', ');
      lines.add('  XMLTV ids that match no playlist channel: $shown');
    }
    return lines.isEmpty ? '' : lines.join('\n');
  }

  /// Picks artwork. `<image type="still" orient="L">` (or any landscape image)
  /// is the best fit for the wide thumbnails; portrait posters are kept
  /// separately for the details sheet. A plain `<icon>` counts as either.
  static _Artwork _artwork(XmlElement element) {
    String? still;
    String? landscape;
    String? poster;
    String? other;
    for (final node in element.childElements) {
      final name = node.name.local;
      if (name != 'image' && name != 'icon') {
        continue;
      }
      final source = (node.getAttribute('src') ?? node.innerText).trim();
      if (source.isEmpty) {
        continue;
      }
      final type = node.getAttribute('type')?.toLowerCase() ?? '';
      final orient = node.getAttribute('orient')?.toUpperCase() ?? '';
      if (type == 'still') {
        still ??= source;
      } else if (orient == 'L') {
        landscape ??= source;
      } else if (type == 'poster' || orient == 'P') {
        poster ??= source;
      } else {
        other ??= source;
      }
    }
    final wide = still ?? landscape;
    return _Artwork(
      landscape: wide ?? other ?? poster,
      poster: poster ?? (wide != null ? other : null),
    );
  }

  static List<ProgrammeCredit> _credits(XmlElement element) {
    final result = <ProgrammeCredit>[];
    for (final block in element.findElements('credits')) {
      for (final node in block.childElements) {
        final name = node.innerText.trim();
        if (name.isEmpty) {
          continue;
        }
        final character = node.getAttribute('role')?.trim();
        result.add(
          ProgrammeCredit(
            role: node.name.local,
            name: name,
            character:
                character == null || character.isEmpty ? null : character,
          ),
        );
      }
    }
    return result;
  }

  static int? _lengthSeconds(XmlElement element) {
    for (final node in element.findElements('length')) {
      final value = double.tryParse(node.innerText.trim());
      if (value == null || value <= 0) {
        continue;
      }
      final units = node.getAttribute('units')?.toLowerCase() ?? 'minutes';
      final seconds = switch (units) {
        'seconds' => value,
        'hours' => value * 3600,
        _ => value * 60,
      };
      return seconds.round();
    }
    return null;
  }

  static String? _rating(XmlElement element) {
    for (final node in element.findElements('rating')) {
      final value = node.findElements('value').firstOrNull?.innerText.trim() ??
          node.innerText.trim();
      if (value.isEmpty) {
        continue;
      }
      final system = node.getAttribute('system')?.trim();
      return system == null || system.isEmpty ? value : '$value ($system)';
    }
    return null;
  }

  static String _firstText(XmlElement element, String name) {
    return _optionalText(element, name) ?? '';
  }

  static String? _optionalText(XmlElement element, String name) {
    for (final node in element.findElements(name)) {
      final value = node.innerText.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static String? _episodeNumber(XmlElement element) {
    for (final node in element.findElements('episode-num')) {
      final system = node.getAttribute('system')?.toLowerCase() ?? '';
      final value = node.innerText.trim();
      if (value.isEmpty) {
        continue;
      }
      if (system == 'onscreen') {
        return value;
      }
      if (system == 'xmltv_ns' || system.isEmpty) {
        final parts = value.split('/').first.split('.');
        final season = _parseIndex(parts, 0);
        final episode = _parseIndex(parts, 1);
        if (season != null || episode != null) {
          final buffer = StringBuffer();
          if (season != null) {
            buffer.write('S${season.toString().padLeft(2, '0')}');
          }
          if (episode != null) {
            buffer.write('E${episode.toString().padLeft(2, '0')}');
          }
          return buffer.toString();
        }
      }
    }
    return null;
  }

  static int? _parseIndex(List<String> parts, int index) {
    if (index >= parts.length) {
      return null;
    }
    final value = parts[index].trim();
    if (value.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(value);
    return parsed == null ? null : parsed + 1;
  }
}

class _Artwork {
  const _Artwork({this.landscape, this.poster});

  final String? landscape;
  final String? poster;
}

class _DropStats {
  int seen = 0;
  int badTime = 0;
  int outsideWindow = 0;
  int noTitle = 0;
}

/// XMLTV timestamps look like `20261028142553 +0000`. Seconds and the zone
/// are optional in the wild, so accept both and treat a missing zone as local
/// time.
DateTime? parseXmltvTime(String? raw) {
  if (raw == null) {
    return null;
  }
  final value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  final match = RegExp(
    r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})?\s*([+-]\d{2}:?\d{2})?$',
  ).firstMatch(value);
  if (match == null) {
    return null;
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.tryParse(match.group(6) ?? '') ?? 0;
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  if (hour > 23 || minute > 59 || second > 59) {
    return null;
  }

  final local = DateTime(year, month, day, hour, minute, second);
  final zone = match.group(7);
  if (zone == null || zone.isEmpty) {
    return local;
  }
  final sign = zone.startsWith('-') ? -1 : 1;
  final digits = zone.substring(1).replaceAll(':', '');
  final offsetHours = int.parse(digits.substring(0, 2));
  final offsetMinutes = int.parse(digits.substring(2, 4));
  final offset = Duration(hours: offsetHours, minutes: offsetMinutes);
  return DateTime.utc(year, month, day, hour, minute, second)
      .subtract(offset * sign)
      .toLocal();
}

/// Maps XMLTV channel ids and display names onto Mawjac channels.
class _ChannelCatalogue {
  _ChannelCatalogue(this._channels);

  final List<Channel> _channels;
  final Map<String, String> _byNormalizedName = <String, String>{};
  final Map<String, String> _resolved = <String, String>{};
  final Map<String, String> names = <String, String>{};
  final Set<String> _unmatchedIds = <String>{};

  int get unmatched => _unmatchedIds.length;

  void register(String xmltvId, List<String> displayNames) {
    final internal = _match(xmltvId, displayNames);
    if (internal == null) {
      _unmatchedIds.add(xmltvId);
    }
    _resolved[xmltvId] = internal ?? '';
    if (internal != null) {
      names[xmltvId] = displayNames.firstOrNull ?? internal;
      for (final name in displayNames) {
        _byNormalizedName.putIfAbsent(_normalize(name), () => internal);
      }
    }
  }

  String? resolve(String xmltvId) {
    final resolved = _resolved[xmltvId];
    if (resolved != null) {
      return resolved.isEmpty ? null : resolved;
    }
    final internal = _match(xmltvId, const <String>[]);
    _resolved[xmltvId] = internal ?? '';
    if (internal == null) {
      _unmatchedIds.add(xmltvId);
    }
    return internal;
  }

  String? _match(String xmltvId, List<String> displayNames) {
    // Programmes without a channel attribute must never match channels that
    // happen to have an empty tvg-id/channel-id.
    if (xmltvId.isEmpty) {
      return null;
    }
    for (final channel in _channels) {
      if (channel.tvgId.isNotEmpty && channel.tvgId == xmltvId) {
        return channel.id;
      }
      if (channel.channelId.isNotEmpty && channel.channelId == xmltvId) {
        return channel.id;
      }
    }

    final normalizedId = _normalize(xmltvId);
    for (final channel in _channels) {
      if (_normalize(channel.tvgId) == normalizedId ||
          _normalize(channel.channelId) == normalizedId) {
        return channel.id;
      }
    }

    for (final name in displayNames) {
      final normalized = _normalize(name);
      if (normalized.isEmpty) {
        continue;
      }
      final known = _byNormalizedName[normalized];
      if (known != null) {
        return known;
      }
      for (final channel in _channels) {
        if (_normalize(channel.name) == normalized) {
          return channel.id;
        }
      }
    }

    if (displayNames.isEmpty) {
      for (final channel in _channels) {
        if (_normalize(channel.name) == normalizedId) {
          return channel.id;
        }
      }
    }
    return null;
  }
}

final RegExp _separatorPattern = RegExp(r'[^0-9A-Za-z\u0600-\u06FF]+');
final RegExp _spacePattern = RegExp(r'\s+');

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(_separatorPattern, '')
      .replaceAll(_spacePattern, '');
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
