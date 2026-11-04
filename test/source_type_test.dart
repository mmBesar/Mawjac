import 'package:flutter_test/flutter_test.dart';
import 'package:mawjac/data/models.dart';

void main() {
  test('Tunarr derives playlist and guide from the service address', () {
    final source = SourceConfig.service(
      id: 'a',
      name: 'Tunarr',
      type: SourceType.tunarr,
      baseUrl: 'http://10.0.0.5:8000/',
    );
    expect(source.m3u.value, 'http://10.0.0.5:8000/api/channels.m3u');
    expect(source.epg.value, 'http://10.0.0.5:8000/api/xmltv.xml');
    expect(source.baseUrl, 'http://10.0.0.5:8000');
  });

  test('ErsatzTV derives playlist and guide, assuming http for a bare host',
      () {
    final source = SourceConfig.service(
      id: 'b',
      name: 'Ersatz',
      type: SourceType.ersatztv,
      baseUrl: 'tv.lan:8409',
    );
    expect(source.m3u.value, 'http://tv.lan:8409/iptv/channels.m3u');
    expect(source.epg.value, 'http://tv.lan:8409/iptv/xmltv.xml');
  });

  test('older saved sources load as generic and round-trip the type', () {
    final old = SourceConfig.fromJson(<String, dynamic>{
      'id': 'x',
      'name': 'Old',
      'm3u': 'http://a/b.m3u',
      'epg': 'http://a/b.xml',
    });
    expect(old.type, SourceType.generic);
    expect(old.isService, isFalse);

    final service = SourceConfig.service(
      id: 'c',
      name: 'T',
      type: SourceType.tunarr,
      baseUrl: 'http://h',
    );
    final back = SourceConfig.fromJson(service.toJson());
    expect(back.type, SourceType.tunarr);
    expect(back.baseUrl, 'http://h');
    expect(back.copyWith(name: 'Z').type, SourceType.tunarr);
  });
}
