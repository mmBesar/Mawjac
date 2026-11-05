import 'package:flutter/material.dart';

/// Soft, distinct colours for the player's control icons, so each action is
/// recognised at a glance. Anything not listed stays white.
Color osdIconColor(IconData icon) {
  if (icon == Icons.star_rounded || icon == Icons.star_outline_rounded) {
    return const Color(0xFFFFC857);
  }
  if (icon == Icons.list_rounded) return const Color(0xFF5CC8FF);
  if (icon == Icons.subtitles_rounded || icon == Icons.audiotrack_rounded) {
    return const Color(0xFFB794F6);
  }
  if (icon == Icons.aspect_ratio_rounded) return const Color(0xFF7BE0AD);
  if (icon == Icons.info_outline_rounded) return const Color(0xFF63B3ED);
  if (icon == Icons.event_note_rounded) return const Color(0xFFFF9F6B);
  if (icon == Icons.keyboard_alt_outlined) return const Color(0xFFA0AEC0);
  if (icon == Icons.monitor_heart_outlined) return const Color(0xFFFC8181);
  if (icon == Icons.picture_in_picture_alt_rounded) {
    return const Color(0xFF4FD1C5);
  }
  if (icon == Icons.volume_up_rounded || icon == Icons.volume_off_rounded) {
    return const Color(0xFF68D391);
  }
  if (icon == Icons.fullscreen_rounded ||
      icon == Icons.fullscreen_exit_rounded) {
    return const Color(0xFFF6E05E);
  }
  return Colors.white;
}
