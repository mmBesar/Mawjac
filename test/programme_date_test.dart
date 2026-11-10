import 'package:flutter_test/flutter_test.dart';
import 'package:mawjac/data/models.dart';

Programme _with(String? date) => Programme(
      channelId: 'x',
      start: DateTime(2026),
      stop: DateTime(2026, 1, 2),
      title: 'T',
      date: date,
    );

void main() {
  group('Programme.displayDate', () {
    test('turns a full XMLTV timestamp into a date', () {
      expect(_with('19790707210000 +0000').displayDate, '1979-07-07');
    });
    test('keeps a bare year', () {
      expect(_with('1979').displayDate, '1979');
    });
    test('handles year and month', () {
      expect(_with('197907').displayDate, '1979-07');
    });
    test('leaves other text alone', () {
      expect(_with('1979-07-07').displayDate, '1979-07-07');
      expect(_with(null).displayDate, isNull);
      expect(_with('  ').displayDate, isNull);
    });
  });

  group('AppSettings new fields', () {
    test('round trip', () {
      final settings = AppSettings.defaults().copyWith(
        externalPlayer: 'vlc',
        guideThumbnails: true,
      );
      final back = AppSettings.fromJson(settings.toJson());
      expect(back.externalPlayer, 'vlc');
      expect(back.guideThumbnails, isTrue);
    });
    test('defaults when missing', () {
      final json = AppSettings.defaults().toJson()
        ..remove('externalPlayer')
        ..remove('guideThumbnails');
      final back = AppSettings.fromJson(json);
      expect(back.externalPlayer, 'builtin');
      expect(back.guideThumbnails, isFalse);
    });
  });
}
