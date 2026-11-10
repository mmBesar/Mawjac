import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// The apps Mawjac can hand a stream to on Android.
enum ExternalApp {
  mpv('is.xyz.mpv', 'mpv'),
  vlc('org.videolan.vlc', 'VLC');

  const ExternalApp(this.package, this.label);

  final String package;
  final String label;

  static ExternalApp? byName(String name) {
    for (final app in ExternalApp.values) {
      if (app.name == name) {
        return app;
      }
    }
    return null;
  }
}

enum ExternalResult { opened, missing, failed }

/// Opens a stream in another Android app (mpv or VLC) through a view intent.
class ExternalPlayer {
  ExternalPlayer._();

  static const MethodChannel _channel = MethodChannel('mawjac/external');

  static Future<ExternalResult> launch({
    required ExternalApp app,
    required String url,
    required String title,
  }) async {
    if (!Platform.isAndroid) {
      return ExternalResult.failed;
    }
    try {
      final result = await _channel.invokeMethod<String>(
        'launch',
        <String, String>{'url': url, 'title': title, 'package': app.package},
      );
      switch (result) {
        case 'ok':
          return ExternalResult.opened;
        case 'missing':
          return ExternalResult.missing;
        default:
          return ExternalResult.failed;
      }
    } on PlatformException {
      return ExternalResult.failed;
    } on MissingPluginException {
      return ExternalResult.failed;
    }
  }
}
