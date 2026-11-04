import 'dart:math';

import '../core/catppuccin.dart';

/// A user-configured playlist/EPG pair. Every source keeps its own M3U and
/// XMLTV location, and its own TLS policy.
enum EndpointKind { url, file }

class SourceEndpoint {
  const SourceEndpoint({required this.value, this.kind = EndpointKind.url});

  final String value;
  final EndpointKind kind;

  bool get isFile => kind == EndpointKind.file;
  bool get isEmpty => value.trim().isEmpty;

  SourceEndpoint copyWith({String? value, EndpointKind? kind}) {
    return SourceEndpoint(
      value: value ?? this.value,
      kind: kind ?? this.kind,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'value': value,
        'kind': kind.name,
      };

  factory SourceEndpoint.fromJson(dynamic json) {
    if (json is String) {
      return SourceEndpoint(value: json);
    }
    if (json is Map) {
      final map = json.cast<String, dynamic>();
      final kindName = map['kind'] as String? ?? 'url';
      return SourceEndpoint(
        value: map['value'] as String? ?? '',
        kind: EndpointKind.values.firstWhere(
          (value) => value.name == kindName,
          orElse: () => EndpointKind.url,
        ),
      );
    }
    return const SourceEndpoint(value: '');
  }
}

/// How a source is configured. Tunarr and ErsatzTV only need the service
/// address; the playlist and guide locations follow from it.
enum SourceType {
  generic,
  tunarr,
  ersatztv;

  /// Turns what the user typed into a base URL without a trailing slash,
  /// assuming http:// for a bare host.
  static String normalizeBase(String input) {
    var value = input.trim();
    if (value.isEmpty) {
      return value;
    }
    if (!value.contains('://')) {
      value = 'http://$value';
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  String playlistUrl(String base) {
    final root = normalizeBase(base);
    return switch (this) {
      SourceType.tunarr => '$root/api/channels.m3u',
      SourceType.ersatztv => '$root/iptv/channels.m3u',
      SourceType.generic => root,
    };
  }

  String guideUrl(String base) {
    final root = normalizeBase(base);
    return switch (this) {
      SourceType.tunarr => '$root/api/xmltv.xml',
      SourceType.ersatztv => '$root/iptv/xmltv.xml',
      SourceType.generic => '',
    };
  }
}

class SourceConfig {
  const SourceConfig({
    required this.id,
    required this.name,
    required this.m3u,
    required this.epg,
    this.allowInsecureCerts = false,
    this.type = SourceType.generic,
    this.baseUrl = '',
  });

  /// A Tunarr or ErsatzTV source built from just the service address.
  factory SourceConfig.service({
    required String id,
    required String name,
    required SourceType type,
    required String baseUrl,
    bool allowInsecureCerts = false,
  }) {
    final base = SourceType.normalizeBase(baseUrl);
    return SourceConfig(
      id: id,
      name: name,
      m3u: SourceEndpoint(value: type.playlistUrl(base)),
      epg: SourceEndpoint(value: type.guideUrl(base)),
      allowInsecureCerts: allowInsecureCerts,
      type: type,
      baseUrl: base,
    );
  }

  final SourceType type;
  final String baseUrl;
  bool get isService => type != SourceType.generic;

  final String id;
  final String name;
  final SourceEndpoint m3u;
  final SourceEndpoint epg;
  final bool allowInsecureCerts;

  SourceConfig copyWith({
    String? name,
    SourceEndpoint? m3u,
    SourceEndpoint? epg,
    bool? allowInsecureCerts,
  }) {
    return SourceConfig(
      id: id,
      name: name ?? this.name,
      m3u: m3u ?? this.m3u,
      epg: epg ?? this.epg,
      allowInsecureCerts: allowInsecureCerts ?? this.allowInsecureCerts,
      type: type,
      baseUrl: baseUrl,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'm3u': m3u.toJson(),
        'epg': epg.toJson(),
        'allowInsecureCerts': allowInsecureCerts,
        'type': type.name,
        'baseUrl': baseUrl,
      };

  factory SourceConfig.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] as String?)?.trim() ?? '';
    final rawName = (json['name'] as String?)?.trim() ?? '';
    return SourceConfig(
      id: rawId.isEmpty ? generateSourceId() : rawId,
      name: rawName.isEmpty ? 'Source' : rawName,
      m3u: SourceEndpoint.fromJson(json['m3u']),
      epg: SourceEndpoint.fromJson(json['epg']),
      allowInsecureCerts: json['allowInsecureCerts'] as bool? ?? false,
      type: SourceType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => SourceType.generic,
      ),
      baseUrl: json['baseUrl'] as String? ?? '',
    );
  }
}

class Channel {
  const Channel({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.number,
    required this.url,
    this.tvgId = '',
    this.channelId = '',
    this.logoUrl,
    this.group,
  });

  /// Stable internal identity, unique per source.
  final String id;
  final String sourceId;
  final String name;
  final String number;
  final String url;
  final String tvgId;
  final String channelId;
  final String? logoUrl;
  final String? group;

  String get displayNumber => number.isEmpty ? '—' : number;
}

/// One person credited on a programme: an actor (with the role they play),
/// a director, a writer and so on. [role] is the XMLTV element name.
class ProgrammeCredit {
  const ProgrammeCredit({
    required this.role,
    required this.name,
    this.character,
  });

  final String role;
  final String name;
  final String? character;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'role': role,
        'name': name,
        'character': character,
      };

  static ProgrammeCredit? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final name = json['name'] as String? ?? '';
    if (name.isEmpty) {
      return null;
    }
    return ProgrammeCredit(
      role: json['role'] as String? ?? 'actor',
      name: name,
      character: json['character'] as String?,
    );
  }
}

class Programme {
  const Programme({
    required this.channelId,
    required this.start,
    required this.stop,
    required this.title,
    this.subTitle,
    this.description,
    this.categories = const <String>[],
    this.iconUrl,
    this.episode,
    this.credits = const <ProgrammeCredit>[],
    this.date,
    this.keywords = const <String>[],
    this.lengthSeconds,
    this.rating,
    this.posterUrl,
    this.previouslyShown = false,
  });

  final String channelId;
  final DateTime start;
  final DateTime stop;
  final String title;
  final String? subTitle;
  final String? description;
  final List<String> categories;
  final String? iconUrl;
  final String? episode;

  /// Cast and crew in document order.
  final List<ProgrammeCredit> credits;

  /// Original air date or production year, as the guide wrote it.
  final String? date;
  final List<String> keywords;

  /// Length of the programme itself when the guide states it.
  final int? lengthSeconds;
  final String? rating;

  /// Portrait artwork when the guide has both it and a landscape image;
  /// [iconUrl] is the best landscape one.
  final String? posterUrl;
  final bool previouslyShown;

  /// Episode number and sub-title for one line of text, e.g.
  /// `S01E05 · The Cat Concerto`. Either half may be missing.
  String? get subtitleLine {
    final number = episode?.trim() ?? '';
    final name = subTitle?.trim() ?? '';
    if (number.isEmpty && name.isEmpty) {
      return null;
    }
    if (number.isEmpty) {
      return name;
    }
    if (name.isEmpty) {
      return number;
    }
    if (name.toLowerCase().contains(number.toLowerCase())) {
      return name;
    }
    return '$number · $name';
  }

  /// Title with the episode label, e.g. `Foo · S01E05`, for tight lists.
  String get displayTitle =>
      episode == null || episode!.isEmpty ? title : '$title · $episode';

  List<ProgrammeCredit> creditsOf(String role) => credits
      .where((credit) => credit.role == role)
      .toList(growable: false);

  bool isLiveAt(DateTime now) => !now.isBefore(start) && now.isBefore(stop);

  bool overlaps(DateTime windowStart, DateTime windowEnd) =>
      stop.isAfter(windowStart) && start.isBefore(windowEnd);

  double progressAt(DateTime now) {
    final total = stop.difference(start).inMilliseconds;
    if (total <= 0) {
      return 0;
    }
    return (now.difference(start).inMilliseconds / total).clamp(0.0, 1.0);
  }
}

/// A programme found by a guide search, with the channel that airs it.
class ProgrammeHit {
  const ProgrammeHit({required this.channel, required this.programme});

  final Channel channel;
  final Programme programme;
}

class Playlist {
  const Playlist({required this.channels, this.xmltvUrl});

  final List<Channel> channels;

  /// The `url-tvg` / `x-tvg-url` advertised by the M3U header, if any.
  final String? xmltvUrl;
}

class EpgData {
  EpgData._(this._byChannel, this.programmeCount);

  factory EpgData.empty() => EpgData._(const <String, List<Programme>>{}, 0);

  factory EpgData.fromMap(Map<String, List<Programme>> byChannel) {
    final frozen = <String, List<Programme>>{};
    var count = 0;
    for (final entry in byChannel.entries) {
      if (entry.value.isEmpty) {
        continue;
      }
      final programmes = List<Programme>.unmodifiable(entry.value);
      frozen[entry.key] = programmes;
      count += programmes.length;
    }
    return EpgData._(Map<String, List<Programme>>.unmodifiable(frozen), count);
  }

  final Map<String, List<Programme>> _byChannel;
  final int programmeCount;

  int get matchedChannels => _byChannel.length;
  bool get isEmpty => programmeCount == 0;

  /// Every programme of every channel, for searching the guide.
  Iterable<Programme> get all => _byChannel.values.expand((list) => list);

  List<Programme> programmesFor(Channel channel) =>
      _byChannel[channel.id] ?? const <Programme>[];

  Programme? nowFor(Channel channel, DateTime now) {
    for (final programme in programmesFor(channel)) {
      if (programme.isLiveAt(now)) {
        return programme;
      }
    }
    return null;
  }

  Programme? nextFor(Channel channel, DateTime now) {
    for (final programme in programmesFor(channel)) {
      if (programme.start.isAfter(now)) {
        return programme;
      }
    }
    return null;
  }

  List<Programme> forWindow(
    Channel channel,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    return programmesFor(channel)
        .where((programme) => programme.overlaps(windowStart, windowEnd))
        .toList(growable: false);
  }
}

enum LoadWarning {
  noEpgEndpoint,
  playlistFromCache,
  epgFromCache,
  epgUnavailable,
  epgEmpty,
}

enum AppLanguage { system, english, arabic }

extension AppLanguageX on AppLanguage {
  String? get localeCode => switch (this) {
        AppLanguage.system => null,
        AppLanguage.english => 'en',
        AppLanguage.arabic => 'ar',
      };
}

class AppSettings {
  const AppSettings({
    required this.themeFamily,
    required this.accent,
    required this.language,
    required this.use24HourTime,
    this.activeSourceId,
    this.useMpvWindow = false,
    this.hwdec = 'config',
    this.videoOutput = 'auto',
    this.useMpvConfig = true,
    this.startFullscreen = false,
    this.mpvPath = '',
    this.autoRefreshMinutes = 360,
    this.guideHours = 12,
    this.inAppRenderer = 'auto',
    this.preferredAudioLang = '',
    this.preferredSubtitleLang = 'off',
    this.rememberTracks = true,
    this.zapBanner = true,
  });

  factory AppSettings.defaults() => const AppSettings(
        themeFamily: ThemeFamily.mawj,
        accent: ThemeAccent.peach,
        language: AppLanguage.system,
        use24HourTime: false,
      );

  final ThemeFamily themeFamily;
  final ThemeAccent accent;
  final AppLanguage language;
  final bool use24HourTime;
  final String? activeSourceId;

  /// Desktop only: play in a separate native mpv window (true) or inside
  /// the app with the built-in renderer (false).
  final bool useMpvWindow;

  /// mpv `--hwdec` value, picked from what the system reports.
  final String hwdec;

  /// mpv `--vo` value, or `auto` to leave mpv's default.
  final String videoOutput;

  /// Load the user's own `~/.config/mpv` configuration and scripts.
  final bool useMpvConfig;

  /// Desktop in-window video: `auto` and `gpu` use the GPU renderer, `cpu` is
  /// the software fallback if a driver ever misbehaves.
  final String inAppRenderer;

  /// Audio language to prefer (ISO 639, empty = the stream's own default).
  final String preferredAudioLang;

  /// Subtitle language to prefer, or `off`.
  final String preferredSubtitleLang;

  /// Remember the audio/subtitle choice per channel.
  final bool rememberTracks;

  /// Show the channel banner when zapping on desktop.
  final bool zapBanner;

  /// Open the mpv window fullscreen.
  final bool startFullscreen;

  /// Optional path to the mpv executable; empty means look in PATH.
  final String mpvPath;

  /// How often the playlist and guide reload by themselves; 0 turns it off.
  final int autoRefreshMinutes;

  /// How many hours the guide timeline spans (12 to 72).
  final int guideHours;

  AppSettings copyWith({
    ThemeFamily? themeFamily,
    ThemeAccent? accent,
    AppLanguage? language,
    bool? use24HourTime,
    Object? activeSourceId = _unset,
    bool? useMpvWindow,
    String? hwdec,
    String? videoOutput,
    bool? useMpvConfig,
    bool? startFullscreen,
    String? mpvPath,
    int? autoRefreshMinutes,
    int? guideHours,
    String? inAppRenderer,
    String? preferredAudioLang,
    String? preferredSubtitleLang,
    bool? rememberTracks,
    bool? zapBanner,
  }) {
    return AppSettings(
      themeFamily: themeFamily ?? this.themeFamily,
      accent: accent ?? this.accent,
      language: language ?? this.language,
      use24HourTime: use24HourTime ?? this.use24HourTime,
      activeSourceId: identical(activeSourceId, _unset)
          ? this.activeSourceId
          : activeSourceId as String?,
      useMpvWindow: useMpvWindow ?? this.useMpvWindow,
      hwdec: hwdec ?? this.hwdec,
      videoOutput: videoOutput ?? this.videoOutput,
      useMpvConfig: useMpvConfig ?? this.useMpvConfig,
      startFullscreen: startFullscreen ?? this.startFullscreen,
      mpvPath: mpvPath ?? this.mpvPath,
      autoRefreshMinutes: autoRefreshMinutes ?? this.autoRefreshMinutes,
      guideHours: guideHours ?? this.guideHours,
      inAppRenderer: inAppRenderer ?? this.inAppRenderer,
      preferredAudioLang: preferredAudioLang ?? this.preferredAudioLang,
      preferredSubtitleLang:
          preferredSubtitleLang ?? this.preferredSubtitleLang,
      rememberTracks: rememberTracks ?? this.rememberTracks,
      zapBanner: zapBanner ?? this.zapBanner,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'themeFamily': themeFamily.name,
        'accent': accent.name,
        'language': language.name,
        'use24HourTime': use24HourTime,
        'activeSourceId': activeSourceId,
        'useMpvWindow': useMpvWindow,
        'hwdec': hwdec,
        'videoOutput': videoOutput,
        'useMpvConfig': useMpvConfig,
        'startFullscreen': startFullscreen,
        'mpvPath': mpvPath,
        'autoRefreshMinutes': autoRefreshMinutes,
        'guideHours': guideHours,
        'inAppRenderer': inAppRenderer,
        'preferredAudioLang': preferredAudioLang,
        'preferredSubtitleLang': preferredSubtitleLang,
        'rememberTracks': rememberTracks,
        'zapBanner': zapBanner,
        'settingsVersion': 2,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final migrated = (json['settingsVersion'] as int? ?? 1) < 2;
    return AppSettings(
      themeFamily: _enumByName(
        ThemeFamily.values,
        json['themeFamily'] as String?,
        ThemeFamily.mawj,
      ),
      accent: _enumByName(
        ThemeAccent.values,
        json['accent'] as String?,
        ThemeAccent.peach,
      ),
      language: _enumByName(
        AppLanguage.values,
        json['language'] as String?,
        AppLanguage.system,
      ),
      use24HourTime: json['use24HourTime'] as bool? ?? false,
      activeSourceId: json['activeSourceId'] as String?,
      // The in-window GPU player is the default; the external system mpv is
      // an option. Settings saved before version 2 predate the GPU player.
      useMpvWindow:
          migrated ? false : (json['useMpvWindow'] as bool? ?? false),
      // Settings before version 2 forced 'auto-safe' and a clean mpv; now the
      // user's own mpv config decides unless they chose a decoder themselves.
      hwdec: migrated
          ? 'config'
          : (json['hwdec'] as String? ?? 'config'),
      videoOutput: json['videoOutput'] as String? ?? 'auto',
      useMpvConfig:
          migrated ? true : (json['useMpvConfig'] as bool? ?? true),
      startFullscreen: json['startFullscreen'] as bool? ?? false,
      mpvPath: json['mpvPath'] as String? ?? '',
      autoRefreshMinutes: json['autoRefreshMinutes'] as int? ?? 360,
      guideHours: json['guideHours'] as int? ?? 12,
      inAppRenderer: json['inAppRenderer'] as String? ?? 'auto',
      preferredAudioLang: json['preferredAudioLang'] as String? ?? '',
      preferredSubtitleLang:
          json['preferredSubtitleLang'] as String? ?? 'off',
      rememberTracks: json['rememberTracks'] as bool? ?? true,
      zapBanner: json['zapBanner'] as bool? ?? true,
    );
  }
}

const Object _unset = Object();

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) {
    return fallback;
  }
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}

String generateSourceId() {
  final random = Random.secure();
  final bytes = List<int>.generate(8, (_) => random.nextInt(256));
  final suffix = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}$suffix';
}
