# Changelog

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
