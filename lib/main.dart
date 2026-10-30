import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    MediaKit.ensureInitialized();
  } catch (error) {
    debugPrint('media_kit initialisation failed: $error');
  }

  final state = await AppState.create();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MawjApp(),
    ),
  );
}
