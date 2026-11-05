# Changelog

## 0.5.1

- Fix build error in the Watch page hero card.

## 0.5.0

- Player OSD: wider, pinnable channel banner (pin icon or click away to dismiss; seconds are set in Settings), smaller type that fits phones and still scales up on large screens, an EPG panel with rich programme details, colourful control icons, and the channel's tags and source in the banner.
- Android: touch-friendly OSD with the channel browser, and optional floating picture-in-picture player.
- Watch page: four views (cards, list, compact, wall), bigger channel logos where there is no programme art, the play button no longer covers the logo, wheel-scrollable tag and group chips.
- Display settings: UI scale (Ctrl +/- /0 on desktop), Guide size, OSD seconds. Desktop default scale lowered.
- Fixes: aspect ratio, deinterlace and audio delay reset per channel and with R.

## 0.4.0

- Desktop: the default player is now inside the app window and uses the GPU, with a set-top-box style on-screen display: channel banner with now/next and progress, volume panel, a channel and group browser (C or Enter), number entry, keyboard shortcuts (H), aspect ratio, deinterlace, audio delay and diagnostics. A CPU renderer is available in Settings as a fallback. The system mpv window is optional and now runs with your own default mpv config.
- Audio and subtitle tracks: choose them in the player (S or the button), in the mpv remote, and set preferred languages in Settings. The choice is remembered per channel.
- Sources: Tunarr and ErsatzTV only need the service address; the playlist and guide URLs are derived. Existing sources keep working.
- Guide data is richer: episode number (`S01E05`) shown with the sub-title everywhere, description, cast and crew, date, length, rating, keywords, repeat marker and landscape stills.
- Android: releases are signed with your own key when the signing secrets are set (see docs/BUILDING.md). An APK signed with the debug key cannot be updated by the signed one; uninstall once.
- Linux packages include AppStream metadata.

## 0.3.0

- Search moved into each page: Watch, Favorites and Guide each have a search icon (Ctrl+F opens the one you are on). Watch and Favorites show matching channels and programmes with artwork and sub-titles; in the Guide, matching programmes light up and the rest dim.
- Guide: programme text now slides with the timeline and stays inside the visible part of each bar, starting at the left (or right for Arabic).
- Player: a channel that fails to open right away is retried a few times before any error is shown, and an error clears itself as soon as video plays.
- Guide: bigger default zoom, up to 48 px/min, 12 to 72 hour timeline, swipe between pages with edge hand-off.
- mpv is no longer bundled; Mawjac uses the system mpv (or the path set in Settings).

## 0.2.0

- Desktop: video now plays in a separate native mpv window (Wayland-safe, GPU decoding, real fullscreen, mpv's own controls). Mawjac shows a now-playing remote beside it. `MAWJAC_MPV` or the Settings path overrides the mpv binary.
- Settings: player engine, hardware decoder (listed from what the installed mpv reports), video output, own mpv config, start fullscreen.
- Desktop layout: sidebar with Ctrl+1..4, Ctrl+F and Ctrl+R shortcuts; wide thumbnail tiles.
- Channels: tap the logo to play, tap the name or programme to open that channel's own guide. In the guide grid, a long press or right click on a channel opens its guide.
- Programme artwork is shown landscape (16:9) in cards and the detail sheet.
- Images: shared keep-alive HTTP clients and more parallel fetches, so logos and artwork load much faster on self-hosted servers.
- Desktop waves are drawn still, to stop idle GPU use.

## 0.1.0

- First release: Watch, Guide, Search, Player and Settings.
- M3U + XMLTV with Tunarr and ErsatzTV; favorites, groups, recents.
- Arabic/English with RTL; Mawj, Foam, Catppuccin and AMOLED themes.
