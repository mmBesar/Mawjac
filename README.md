<div align="center">

# Mawjac · موجة

**A fast, light IPTV player for Android and Linux, with a set-top-box style on-screen display.**

[![Build](https://github.com/mmBesar/Mawjac/actions/workflows/build.yml/badge.svg)](https://github.com/mmBesar/Mawjac/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/mmBesar/Mawjac?include_prereleases&sort=semver)](https://github.com/mmBesar/Mawjac/releases)
[![Licence: GPL-3.0-or-later](https://img.shields.io/badge/licence-GPL--3.0--or--later-blue.svg)](LICENSE)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20Linux-3ddc84)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Player](https://img.shields.io/badge/player-mpv-8d6aa8)
![Languages](https://img.shields.io/badge/UI-English%20%7C%20العربية-informational)
![Status](https://img.shields.io/badge/status-under%20development-orange)

</div>

> [!WARNING]
> **Personal project, under active development.**
> Mawjac is built first for my own use and shared as-is. Features change,
> settings may be reset between versions, and bugs are expected. It is not
> production software and nothing here is promised: no roadmap, no support
> schedule, no guarantee that a given release works on your device.

Mawjac (موجة, "a wave") reads M3U playlists and XMLTV guides and is tested
against **Tunarr** and **ErsatzTV**. Arabic and English with full right-to-left
layout, Catppuccin themes and an AMOLED black theme.

## Features

**Watching**
- Hero strip to resume, filter pills for All, Favorites and groups or tags (scroll them with the wheel or by swiping).
- Four ways to browse channels: cards, list, compact and wall. Live "now" progress on every channel.
- Search for channels and programmes, with Arabic-aware matching (diacritics, alef and ya/ta-marbuta variants).
- Favorites and recents survive playlist reordering, because channel ids come from `tvg-id`, `channel-id` or the name, never the position.

**Guide**
- 12-hour timeline with a now line, optional favorites-only view, adjustable guide size.
- Rich programme details when the source provides them: episode number (`S01E05`), sub-title, cast and crew, date, length, rating, keywords, stills and a repeat badge.

**Player**
- Plays in the app's own window on the GPU, or hands over to your system **mpv** (using your own mpv config) while Mawjac stays open as a remote.
- Set-top-box OSD: pinnable channel banner with stream details, channel browser, EPG panel, volume and brightness, number entry, audio and subtitle menu, shortcut help (`H`).
- Audio and subtitle tracks with preferred languages and per-channel memory; aspect ratio, deinterlace and audio delay reset on each channel (or with `R`).
- Android: touch OSD, swipe for volume and brightness, optional floating picture-in-picture window.
- Stall detection with copyable diagnostics.

**Look and feel**
- Themes: Mawj (dark), Foam (light), Catppuccin Latte, Frappé, Macchiato and Mocha, AMOLED, and system colours.
- UI scale for desktop (Ctrl + / Ctrl − / Ctrl 0), separate guide size, OSD timing.

## Sources

Mawjac does not ship or sell any channels. You add your own sources in the app:

| Type | What you enter |
| --- | --- |
| **Generic** | a playlist (M3U) address and, optionally, a guide (XMLTV) address |
| **Tunarr** | the service address only, e.g. `http://192.168.1.10:8000` |
| **ErsatzTV** | the service address only |

Details and examples are in [docs/SOURCES.md](docs/SOURCES.md).

## Install

Builds come from GitHub Actions: an Android arm64 APK and Linux amd64 and arm64
packages (AppImage, DEB and RPM). Download them from the artifacts of a
[Build run](https://github.com/mmBesar/Mawjac/actions/workflows/build.yml), or from
[Releases](https://github.com/mmBesar/Mawjac/releases) once a version is published.

## Desktop playback

By default Mawjac plays inside its own window on the GPU. If a driver misbehaves,
Settings has a CPU renderer, or set `MAWJAC_RENDERER=cpu`. Linux hardware decoding
is off by default; try `MAWJAC_HWDEC=auto-copy-safe`.

To use your system mpv instead, enable **Use system mpv** in Settings. mpv is found
on `PATH`, at the path set in Settings, or at `MAWJAC_MPV=/path/to/mpv`.

**ErsatzTV note:** its HLS master advertises a WebVTT subtitle rendition, and
media_kit's default ffmpeg option (`strict=experimental`) then makes ffmpeg read
only that rendition and never open the video. Mawjac sets its own demuxer options
without that flag.

## Build from source

```bash
tool/bootstrap.sh
flutter run -d linux
```

See [docs/BUILDING.md](docs/BUILDING.md) for platform setup and Android signing.
Changes are listed in the [CHANGELOG](CHANGELOG.md).

## Disclaimer

- **No content provided.** Mawjac is only a player. It includes no channels,
  playlists, guides or streams, and I do not host, link to or endorse any.
- **Your responsibility.** You are responsible for making sure that what you
  watch through Mawjac is legal where you live and that you have the right to
  use it.
- **No affiliation.** Not affiliated with or endorsed by Tunarr, ErsatzTV, mpv,
  Tvheadend, Flutter, Catppuccin or any broadcaster or provider. Names are used
  only to describe compatibility.
- **Built with AI assistance.** Mawjac is developed by me with the help of an
  AI coding assistant (Claude, by Anthropic). I direct the work, test it on my
  own devices and decide what ships, but much of the code was written or
  refactored by the assistant and may contain mistakes a human would not make.
  Treat it accordingly.
- **No warranty.** Provided "as is", without warranty of any kind, as stated in
  the licence. Use it at your own risk.
- **Privacy.** Mawjac has no accounts, analytics or telemetry. It connects only to
  the sources you configure, and sends them its own user-agent. Source settings are
  stored on your device.

## Related

**MawjTVH** is a sibling client for Tvheadend that shares Mawjac's design and
player code.

## Contributing

This is a personal project, so response times are slow and some ideas will not
fit. Bug reports with the copied diagnostics from the player are the most useful
thing. See [SECURITY.md](SECURITY.md) for reporting security problems.

## Licence

Copyright © Mohammed Besar (mmBesar). Licensed under the
**GNU General Public License v3.0 or later**; see [LICENSE](LICENSE).
Derivatives must remain open source under the same terms.
