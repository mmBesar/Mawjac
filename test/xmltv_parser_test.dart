import 'package:flutter_test/flutter_test.dart';
import 'package:mawjac/data/models.dart';
import 'package:mawjac/data/xmltv_parser.dart';

void main() {
  const parser = XmltvParser();
  const channels = <Channel>[
    Channel(
      id: 'internal-one',
      sourceId: 'source',
      name: 'Arabic One',
      number: '1',
      url: 'https://example.com/one',
      tvgId: 'C1.tunarr.com',
      channelId: 'C1.tunarr.com',
    ),
    Channel(
      id: 'internal-two',
      sourceId: 'source',
      name: 'News Two',
      number: '2',
      url: 'https://example.com/two',
    ),
  ];

  test('parses programmes, sub-titles and matches tvg-id', () {
    const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="C1.tunarr.com">
    <display-name>Arabic One</display-name>
  </channel>
  <programme start="20261028142553 +0000" stop="20261028154453 +0000" channel="C1.tunarr.com">
    <title>وجهة نظر</title>
    <sub-title>حلقة 1</sub-title>
    <desc>وصف الحلقة</desc>
    <category>دراما</category>
    <category>كوميديا</category>
    <icon src="https://example.com/poster.jpg"/>
    <episode-num system="xmltv_ns">0.1.</episode-num>
  </programme>
  <programme start="20270101120000 +0000" stop="20270101130000 +0000" channel="C1.tunarr.com">
    <title>Outside the window</title>
  </programme>
</tv>
''';

    final result = parser.parse(
      xml,
      channels,
      now: DateTime.utc(2026, 10, 28, 14, 30),
    );
    final epg = result.epg;

    expect(result.matchedChannels, 1);
    expect(epg.programmeCount, 1);

    final programme = epg.programmesFor(channels.first).single;
    expect(programme.title, 'وجهة نظر');
    expect(programme.subTitle, 'حلقة 1');
    expect(programme.description, 'وصف الحلقة');
    expect(programme.categories, <String>['دراما', 'كوميديا']);
    expect(programme.iconUrl, 'https://example.com/poster.jpg');
    expect(programme.episode, 'S01E02');
    expect(programme.start.toUtc(), DateTime.utc(2026, 10, 28, 14, 25, 53));
    expect(programme.stop.toUtc(), DateTime.utc(2026, 10, 28, 15, 44, 53));
    expect(epg.nowFor(channels.first, DateTime.utc(2026, 10, 28, 14, 30)), isNotNull);
  });

  test('matches by display name when the playlist has no tvg-id', () {
    const xml = '''
<tv>
  <channel id="some.random.id">
    <display-name>News Two</display-name>
  </channel>
  <programme start="20261028140000 +0000" stop="20261028150000 +0000" channel="some.random.id">
    <title>Midday News</title>
  </programme>
</tv>
''';

    final result = parser.parse(
      xml,
      channels,
      now: DateTime.utc(2026, 10, 28, 14, 30),
    );

    expect(result.epg.programmesFor(channels[1]).single.title, 'Midday News');
    expect(result.unmatchedChannels, 0);
  });

  test('reports channels that cannot be matched', () {
    const xml = '''
<tv>
  <channel id="unknown"><display-name>Unknown</display-name></channel>
</tv>
''';

    final result = parser.parse(
      xml,
      channels,
      now: DateTime.utc(2026, 10, 28, 14, 30),
    );

    expect(result.epg.isEmpty, isTrue);
    expect(result.unmatchedChannels, 1);
  });

  test('does not match programmes with an empty channel attribute', () {
    const xml = '''
<tv>
  <programme start="20261028140000 +0000" stop="20261028150000 +0000">
    <title>No channel</title>
  </programme>
</tv>
''';

    final result = parser.parse(
      xml,
      channels,
      now: DateTime.utc(2026, 10, 28, 14, 30),
    );

    expect(result.epg.isEmpty, isTrue);
    expect(result.matchedChannels, 0);
  });

  test('falls back to the sub-title when a programme has no title', () {
    const xml = '''
<tv>
  <programme start="20261028140000 +0000" stop="20261028150000 +0000"
             channel="C1.tunarr.com">
    <sub-title>Placeholder block</sub-title>
  </programme>
</tv>
''';

    final result = parser.parse(
      xml,
      channels,
      now: DateTime.utc(2026, 10, 28, 14, 30),
    );

    expect(result.epg.programmesFor(channels[0]).single.title,
        'Placeholder block');
  });

  test('reports why a channel has no guide', () {
    const xml = '''
<tv>
  <programme start="20261028140000 +0000" stop="20261028150000 +0000"
             channel="C1.tunarr.com">
    <title>Kept</title>
  </programme>
  <programme start="20261028140000 +0000" stop="20261028150000 +0000"
             channel="unknown.id">
    <title>Orphan</title>
  </programme>
</tv>
''';

    final result = parser.parse(
      xml,
      channels,
      now: DateTime.utc(2026, 10, 28, 14, 30),
    );

    expect(result.report, contains('News Two'));
    expect(result.report, contains('unknown.id'));
    expect(result.report, isNot(contains('Arabic One')));
  });

  test('parses timezone offsets and rejects malformed timestamps', () {
    expect(
      parseXmltvTime('20261028170000 +0300')!.toUtc(),
      DateTime.utc(2026, 10, 28, 14),
    );
    expect(
      parseXmltvTime('20261028170000 -0430')!.toUtc(),
      DateTime.utc(2026, 10, 28, 21, 30),
    );
    expect(parseXmltvTime('2026-10-28 17:00'), isNull);
    expect(parseXmltvTime(null), isNull);
  });

  group('rich programme data', () {
    // A recent window so the programme is kept whatever day the test runs.
    String stamp(DateTime time) {
      final utc = time.toUtc();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${utc.year}${two(utc.month)}${two(utc.day)}'
          '${two(utc.hour)}${two(utc.minute)}${two(utc.second)} +0000';
    }

    final now = DateTime.now();
    final start = stamp(now.subtract(const Duration(minutes: 10)));
    final stop = stamp(now.add(const Duration(minutes: 20)));

    test('Tunarr: episode number from xmltv_ns, credits, length, rating', () {
      final xml = '''
<tv>
  <channel id="C1.tunarr.com"><display-name>Arabic One</display-name></channel>
  <programme start="$start" stop="$stop" channel="C1.tunarr.com">
    <title>Tom and Jerry</title>
    <sub-title>The Cat Concerto</sub-title>
    <desc>A concert goes wrong.</desc>
    <date>1947</date>
    <category>Animation</category>
    <keyword>cat</keyword>
    <keyword>mouse</keyword>
    <length units="seconds">420</length>
    <icon src="https://example.com/poster.jpg"/>
    <episode-num system="xmltv_ns">0.4.0/1</episode-num>
    <rating system="VCHIP"><value>TV-Y7</value></rating>
    <credits>
      <director>William Hanna</director>
      <actor role="Tom">Mel Blanc</actor>
    </credits>
  </programme>
</tv>''';
      final result = parser.parse(xml, channels);
      final programme = result.epg.programmesFor(channels.first).single;
      expect(programme.episode, 'S01E05');
      expect(programme.subtitleLine, 'S01E05 · The Cat Concerto');
      expect(programme.displayTitle, 'Tom and Jerry · S01E05');
      expect(programme.date, '1947');
      expect(programme.keywords, <String>['cat', 'mouse']);
      expect(programme.lengthSeconds, 420);
      expect(programme.rating, 'TV-Y7 (VCHIP)');
      expect(programme.iconUrl, 'https://example.com/poster.jpg');
      expect(programme.creditsOf('director').single.name, 'William Hanna');
      expect(programme.creditsOf('actor').single.character, 'Tom');
    });

    test('ErsatzTV: onscreen number wins, landscape still beats poster', () {
      final xml = '''
<tv>
  <channel id="C1.tunarr.com"><display-name>Arabic One</display-name></channel>
  <programme start="$start" stop="$stop" channel="C1.tunarr.com">
    <title lang="en">Show</title>
    <category lang="en">Drama</category>
    <episode-num system="onscreen">S02E10</episode-num>
    <episode-num system="xmltv_ns">1.9.</episode-num>
    <icon src="https://example.com/poster.jpg"/>
    <image type="poster" orient="P">https://example.com/p.jpg</image>
    <image type="still" orient="L">https://example.com/still.jpg</image>
    <previously-shown/>
  </programme>
</tv>''';
      final programme = parser
          .parse(xml, channels)
          .epg
          .programmesFor(channels.first)
          .single;
      expect(programme.episode, 'S02E10');
      expect(programme.subtitleLine, 'S02E10');
      expect(programme.iconUrl, 'https://example.com/still.jpg');
      expect(programme.posterUrl, 'https://example.com/p.jpg');
      expect(programme.previouslyShown, isTrue);
    });

    test('does not repeat an episode number already in the sub-title', () {
      final programme = Programme(
        channelId: 'x',
        start: DateTime(2026),
        stop: DateTime(2026, 1, 2),
        title: 'T',
        subTitle: 'S01E05 - Name',
        episode: 'S01E05',
      );
      expect(programme.subtitleLine, 'S01E05 - Name');
    });
  });
}
