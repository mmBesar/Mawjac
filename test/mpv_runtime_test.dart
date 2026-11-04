import 'package:flutter_test/flutter_test.dart';
import 'package:mawjac/data/mpv_runtime.dart';

void main() {
  const help = '''
Valid values for option hwdec:
  no
  auto
  auto-safe
  auto-copy
  auto-copy-safe
  vaapi
  vaapi-copy
  nvdec (cuda)
  drm
Note: something else, not a value.
''';

  const capabilities = MpvCapabilities(
    path: '/usr/bin/mpv',
    version: 'mpv 0.40.0',
    hwdecs: <String>['no', 'auto', 'auto-safe', 'vaapi', 'nvdec'],
    bundled: false,
    supportsWaylandAppId: true,
  );

  test('parses the hwdec list from mpv', () {
    expect(MpvRuntime.parseHwdecHelp(help), <String>[
      'no',
      'auto',
      'auto-safe',
      'auto-copy',
      'auto-copy-safe',
      'vaapi',
      'vaapi-copy',
      'nvdec',
      'drm',
    ]);
  });

  test('offers only specific decoders by name', () {
    expect(capabilities.specificHwdecs, <String>['vaapi', 'nvdec']);
  });

  test('builds a command line without the experimental HLS flag', () {
    final arguments = MpvRuntime.buildArguments(
      capabilities: capabilities,
      title: 'Mawjac · One',
      ipcPath: '/run/user/1000/mawjac.sock',
      hwdec: 'vaapi',
      videoOutput: 'gpu-next',
      allowInsecure: true,
      useUserConfig: false,
      fullscreen: true,
    );
    expect(arguments, contains('--no-config'));
    expect(arguments, contains('--hwdec=vaapi'));
    expect(arguments, contains('--vo=gpu-next'));
    expect(arguments, contains('--tls-verify=no'));
    expect(arguments, contains('--fs'));
    expect(arguments, contains('--wayland-app-id=com.mmbesar.mawjac.player'));
    expect(arguments.join(' '), isNot(contains('strict=experimental')));
  });

  test('falls back to auto-safe for a decoder the system does not list', () {
    final arguments = MpvRuntime.buildArguments(
      capabilities: capabilities,
      title: 't',
      ipcPath: 's',
      hwdec: 'rkmpp',
      videoOutput: 'auto',
      allowInsecure: false,
      useUserConfig: true,
      fullscreen: false,
    );
    expect(arguments, contains('--hwdec=auto-safe'));
    expect(arguments, isNot(contains('--no-config')));
    expect(arguments, isNot(contains('--cache=yes')));
    expect(arguments.any((a) => a.startsWith('--vo=')), isFalse);
    expect(arguments, contains('--tls-verify=yes'));
  });

  test('leaves decoding to the user config by default', () {
    final arguments = MpvRuntime.buildArguments(
      capabilities: capabilities,
      title: 't',
      ipcPath: 's',
      hwdec: 'config',
      videoOutput: 'auto',
      allowInsecure: false,
      useUserConfig: true,
      fullscreen: false,
    );
    expect(arguments.any((a) => a.startsWith('--hwdec=')), isFalse);
    expect(arguments, isNot(contains('--no-config')));
  });
}
