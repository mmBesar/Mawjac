# Mawjac

**Mawjac** (موجة, "a wave") is a fast, light IPTV player for Android and Linux.
It reads M3U playlists and XMLTV guides and is tested against **Tunarr** and
**ErsatzTV**. Arabic and English with full RTL, Catppuccin themes plus AMOLED.

## What it does

- **Watch**: a hero strip to resume, filter pills for All, Favorites and groups, live "now" progress on every channel.
- **Guide**: a 12-hour timeline with a now line, optional favorites-only view.
- **Search**: channels and programmes, with Arabic-aware matching (diacritics, alef and ya/ta-marbuta variants).
- **Player**: in-place channel zapping, swipe for brightness and volume, native window fullscreen on desktop, stall detection with copyable diagnostics.
- **Themes**: Mawj (dark), Foam (light), Catppuccin Latte/Frappé/Macchiato/Mocha, AMOLED, and system colours.

Favorites and recents survive playlist reordering because channel ids come from `tvg-id`, `channel-id` or name rather than position.

## ErsatzTV note

ErsatzTV's HLS master advertises a WebVTT subtitle rendition. media_kit's default
ffmpeg options (`strict=experimental`) make ffmpeg read only that rendition and
never open the video. Mawjac sets its own demuxer options without that flag.

## Desktop playback

By default Mawjac plays inside its own window on the GPU, with a set-top-box
style on-screen display (channel banner, volume, channel and group browser,
number entry, audio/subtitle menu; press H for the shortcuts). If a driver ever
misbehaves, Settings has a CPU renderer, or set `MAWJAC_RENDERER=cpu`.

Optionally, Mawjac can hand playback to your system **mpv** (Settings, "Use
system mpv"). It runs in its own window with your default mpv config and
scripts, and Mawjac stays open as a remote. mpv is taken from `PATH`, from the
path set in Settings, or from `MAWJAC_MPV=/path/to/mpv`.

## Build

See [docs/BUILDING.md](docs/BUILDING.md) and [docs/SOURCES.md](docs/SOURCES.md).
CI builds an Android arm64 APK and Linux amd64/arm64 bundles.

```bash
tool/bootstrap.sh
flutter run -d linux
```

Linux hardware decoding is off by default; try `MAWJAC_HWDEC=auto-copy-safe`.

## Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).
