# Project notes (for the next developer, human or AI)

Read this first. Keep it current: **every change that matters adds a line to
"Status log" and updates the other sections if they became untrue.**
`AGENTS.md` in the repo root points here.

## What this is
Mawjac (موجة): personal Flutter IPTV player for Android and Linux. M3U + XMLTV,
Tunarr, ErsatzTV. Owner: Mohammed (mmBesar), Arabic speaker, not a coder; he
builds through GitHub Actions and tests on a phone and a Wayland Linux desktop.
Licence GPL-3.0-or-later. Personal project under development (see README).

Sibling project **MawjTVH** (Tvheadend client) shares the OSD, player, theme,
zoom and string code. Fixes made here usually need carrying over there, and
the other way round. See "Sync with MawjTVH".

## Rules of the house
- **AI use is stated openly, not hidden.** The README says the project is
  built with AI assistance. Keep that true and visible; never present AI-written
  work as hand-written. What the owner asked for is narrower: no
  `Co-Authored-By` or session-link trailers in commit messages (they added the
  assistant to GitHub's Contributors list). Commits are authored
  `mmBesar <mbesar@proton.me>`.
- The sandbox where much of this was written has **no Dart/Flutter SDK**, so
  nothing is compiled before it reaches CI. Read changed code twice. CI
  `flutter analyze --no-fatal-infos` fails on errors **and warnings** (unused
  imports, unused private members). Infos are fine.
- Things that already broke CI: an identifier that only existed in another
  class after a merge (`hasArt`), a `const` map holding non-const values, an
  unused import, imports not ASCII-sorted (`directives_ordering`:
  `player_strings.dart` sorts before `strings.dart`), AppStream ids.
- `tool/check_strings.py` (runs in CI before analyze) catches duplicate
  `PlayerStrings` getters and undefined `strings.X`.
- Arabic and English, full RTL. Every user-visible string goes through
  `lib/l10n/strings.dart` or `lib/l10n/player_strings.dart` (both languages).
- Don't ask the owner to run commands he can avoid. Ship a `.7z` of the repo
  (without `.dart_tool`, `build`, `.flutter`) with `.git` included.

## Layout
- `lib/data/` models (`AppSettings`, `SourceConfig`, `Channel`, `Programme`),
  `app_state.dart` (ChangeNotifier, all settings setters), playlist/XMLTV
  parsers, storage, `mpv_runtime.dart` (system mpv over JSON IPC).
- `lib/core/` theme (Catppuccin + AMOLED), `ui_zoom.dart`, `pip.dart`,
  `external_player.dart` (Android mpv/VLC intents), `platform.dart`
  (`kIsDesktop`), `network_image.dart` (limited, cached image fetch).
- `lib/ui/app_shell.dart` tabs: Watch, Favorites, Guide, Settings.
  Desktop uses an IndexedStack and sidebar; Android a PageView and floating nav.
- `lib/ui/player_page.dart` in-app player (media_kit, GPU renderer) and the
  OSD wiring; `lib/ui/widgets/stb_*.dart` OSD pieces (banner, volume card,
  channel browser, EPG panel, help); `desktop_player_page.dart` is the
  system-mpv remote.
- `tool/configure_platforms.py` patches the generated Android/Linux projects
  (manifest, Kotlin `MainActivity` with PiP and external-player channels,
  signing). `.github/workflows/build.yml` builds; `release.yml` publishes.

## Behaviour worth knowing
- Settings changes go through `AppState.updateSettings(copyWith(...))`. A new
  setting needs: field, ctor, copyWith, toJson, fromJson, setter, UI, strings.
- Tab change: neighbours slide, distant tabs fade and `jumpToPage`
  (`_goTo` in app_shell). The guide's edge-drag is ignored while navigating;
  that was the cause of "Settings opens Favorites on a fresh start".
- Player: aspect, deinterlace and audio delay reset on every channel (`R`).
  OSD value cards (volume/brightness) sit in the lower third; notices at top.
  On a small portrait player the browser/EPG panels are drawn over the whole
  page (`_panels`), not inside the video box.
- External players: Android `externalPlayer` = builtin | mpv | vlc, launched by
  `openPlayer` through a view intent; falls back to the built-in player with a
  message if the app is missing. Desktop: "Use system mpv" in Settings.
- Guide programme pictures: optional (`guideThumbnails`), shown only in bars
  at least 280 px wide.
- XMLTV `<date>` is shown through `Programme.displayDate`.
- Releasing: push to main, wait for green Build, then
  `git tag vX.Y.Z && git push origin vX.Y.Z` (or run the Release workflow).
  Nothing is rebuilt; the APK is already release-signed by the Build run via
  the four `ANDROID_*` secrets.

## Sync with MawjTVH (what Mawjac has that TVH may lack)
Aspect/deinterlace/delay reset; Android controls in rows (no overlap); real
cards view on phones; landscape-phone side panels; top/lower-third OSD cards;
info banner and EPG panel as icon rows; hover play button in the tile corner;
check_strings; page navigation fix; external players (Android); guide
thumbnails; displayDate. Mawjac-only by nature: Tunarr/ErsatzTV sources, rich
XMLTV fields, mpv remote track sheet, AppStream, signing.

## Open ideas
- Bundle libmpv 0.42 in the AppImage (needs a source build job, newer
  libplacebo; system mpv already gets new Wayland features).
- Shared core package for Mawjac, MawjTVH and others (owner undecided).
- Favorites page vs favorites chip: owner asked, no decision.

## Status log (newest last)
- 0.4.0: signing, AppStream, system mpv optional, source types, rich EPG, tracks.
- 0.5.0 to 0.5.4: MawjTVH 0.1.5 port (pinnable banner, EPG panel, views, zoom,
  PiP), phone fixes, readme, release workflow.
- 0.6.0: Android external player (mpv, VLC); page navigation fix; optional
  guide thumbnails; audit (removed a double dispose in app_shell; checked
  AppSettings round trip, widget constructor arguments, subscription/timer
  disposal by script). Not compiled; CI must confirm.
- 0.6.1: test fix (build AppSettings from `AppSettings.defaults()`, its constructor has required fields); README discloses AI assistance.
