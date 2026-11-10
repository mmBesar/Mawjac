# Building Mawjac

Mawjac targets Flutter **3.47.8** (Dart **3.13.x**). The generated `android/`
and `linux/` directories are not checked in; they are recreated from the pinned
SDK so that Flutter template changes never conflict with Mawjac's small set of
platform patches.

## Prerequisites

### All platforms

- Git and Python 3 (used by `tool/configure_platforms.py`).
- Network access for the Flutter SDK, pub packages and platform artifacts.
- `bash` for the scripts in `tool/` (Linux and macOS; on Windows use WSL).

### Android

- JDK 17.
- Android SDK with build tools and platform 35 (or whatever the pinned Flutter
  version requests). Android Studio's SDK Manager or the command-line tools
  are both fine.
- Accept the SDK licenses (`flutter doctor --android-licenses`).

### Linux

Ubuntu 24.04 package names:

```bash
sudo apt-get update
sudo apt-get install --yes --no-install-recommends \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libmpv-dev \
  dpkg-dev rpm
```

`libmpv-dev` is only needed to compile/link against libmpv; the resulting
application loads libmpv at runtime, so end users need `libmpv2`/`libmpv1`
(or `mpv-libs` on RPM distributions).

## Get the Flutter SDK

### x86_64 Linux

Install the 3.47.8 stable SDK however you prefer, for example:

```bash
git clone --depth 1 --branch 3.47.8 \
  https://github.com/flutter/flutter.git "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"
```

`tool/bootstrap.sh` does this automatically into `./.flutter` if `flutter` is
not already on `PATH`:

```bash
FLUTTER_VERSION=3.47.8 tool/bootstrap.sh
```

### aarch64 Linux

The GitHub-hosted ARM64 runner is `ubuntu-24.04-arm`. Flutter's prebuilt Linux
SDK archive is not available for every ARM64 release, so CI clones the SDK
source and lets it download the ARM64 Dart SDK and engine artifacts:

```bash
git clone --depth 1 --branch 3.47.8 \
  https://github.com/flutter/flutter.git "$RUNNER_TEMP/flutter"
export PATH="$RUNNER_TEMP/flutter/bin:$PATH"
tool/bootstrap.sh
```

This is exactly what the `linux-arm64` CI job does. It needs network access and
a few minutes on the first run.

## Bootstrap

From the repository root:

```bash
tool/bootstrap.sh
```

The script:

1. Locates Flutter (or clones it into `./.flutter`).
2. Disables analytics and enables Linux desktop.
3. Runs `flutter create --platforms=android,linux --org com.mmbesar
   --project-name mawjac` in a temporary directory, and copies only platform
   folders that do not already exist.
4. Calls `tool/configure_platforms.py` to set the application id
   `com.mmbesar.mawjac`, the Android label, `minSdk` 24, network/wakelock
   permissions, cleartext support, launcher icons and the Linux window title.
5. Runs `flutter pub get`.

Bootstrap is idempotent. Run it again after changing the pinned Flutter version;
existing shell folders are left alone, so delete `android/` or `linux/` if you
need a clean template.

## Build

```bash
# Android, ARM64 only (produces app-release.apk; CI renames it to
# Mawjac-<version>-arm64-v8a.apk for the release)
flutter build apk --release --target-platform android-arm64

# Linux, native host architecture
flutter build linux --release
```

Linux bundle locations:

- `build/linux/x64/release/bundle` (x86_64)
- `build/linux/arm64/release/bundle` (aarch64)

The bundle contains the `mawjac` executable, `lib/` and `data/`. It is not
relocatable on its own unless you preserve that layout, which is why the Linux
packages put it under `/opt/mawjac`.

## Package Linux releases

`tool/package_linux.sh` stages the bundle and produces DEB, RPM and AppImage
artifacts under `dist/`:

```bash
tool/package_linux.sh \
  --bundle build/linux/x64/release/bundle \
  --arch amd64 \
  --formats deb,rpm,appimage
```

| Option | Meaning |
| --- | --- |
| `--bundle DIR` | Flutter release bundle directory |
| `--arch amd64\|arm64` | Target architecture (aliases `x86_64`/`aarch64`) |
| `--version X.Y.Z` | Package version; defaults to `pubspec.yaml` |
| `--out DIR` | Output directory; defaults to `dist` |
| `--formats LIST` | Any subset of `deb,rpm,appimage` |

Details:

- **DEB** — installs into `/opt/mawjac`, adds `/usr/bin/mawjac`, the desktop file
  and a 512×512 icon. Depends on `libgtk-3-0t64 | libgtk-3-0` (Ubuntu 24.04
  renamed the package), `libmpv2 | libmpv1` and the usual C++ runtime
  libraries.
- **RPM** — same layout, requires `gtk3` and `mpv-libs`.
- **AppImage** — bundles the Flutter app under `usr/bin`, sets
  `LD_LIBRARY_PATH` to `usr/bin/lib`, and downloads `appimagetool` for the
  target architecture unless `APPIMAGETOOL` points at an existing binary.
  libmpv is still required from the host.

The AppImage download URLs are:

- `https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage`
- `https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-aarch64.AppImage`

CI runs appimagetool with `APPIMAGE_EXTRACT_AND_RUN=1` because the runner has no
FUSE.

## Continuous integration

`.github/workflows/build.yml` runs on pushes to `main`, pull requests and
manual dispatches. `.github/workflows/release.yml` publishes a release from an
existing green build, without rebuilding.

| Job | Runner | Output |
| --- | --- | --- |
| `quality` | `ubuntu-24.04` | `flutter analyze`, `flutter test` |
| `android` | `ubuntu-24.04` | ARM64 release APK artifact |
| `linux-amd64` | `ubuntu-24.04` | DEB, RPM, AppImage |
| `linux-arm64` | `ubuntu-24.04-arm` | DEB, RPM, AppImage |

The ARM64 runner is free only for **public** repositories. The workflow checks
`github.event.repository.private` and skips the ARM64 leg on private
repositories, so a private fork still builds the x86_64 packages.

To cut a release:

1. Update the version in `pubspec.yaml` and `lib/core/app_info.dart`
   (`kAppVersion`); they must match.
2. Add a `CHANGELOG.md` entry.
3. Commit and push to `main`, and wait for the Build run to go green. With the
   signing secrets set, that run already produces the release-signed APK.
4. Publish: `git tag -a v0.6.2 -m "Mawjac 0.6.2" && git push origin v0.6.2`.
   The Release workflow finds the green Build run for that exact commit, checks
   that every file is there (APK, DEB, RPM and AppImage for amd64 and arm64),
   refuses a debug-signed APK, adds `SHA256SUMS` and creates the release. A
   plain tag (`v0.6.2`) becomes the **latest** release; only a tag with a suffix
   (`v0.7.0-beta1`) is a pre-release. If the commit has no complete green build,
   it starts a new Build on the tag, waits for it and releases only if that is
   green. It can also be started by hand (Actions -> Release -> Run workflow, with
   the tag). The workflow file that runs is the one in the tagged commit, so push
   the commit that contains it to `main` before tagging.

### Signing the Android APK

`tool/configure_platforms.py` patches the generated Gradle file so release
builds are signed with `android/key.properties` when it exists, and with the
debug key otherwise (local builds). In CI the file is written from four
repository secrets (Settings -> Secrets and variables -> Actions):

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_B64` | `base64 -w0 mawjac.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password |
| `ANDROID_KEY_ALIAS` | the alias (`mawjac`) |
| `ANDROID_KEY_PASSWORD` | the key password |

A tag build (`v*`) fails if `ANDROID_KEYSTORE_B64` is missing, so a debug-signed
APK is never published by accident. Keystores, `key.properties` and similar
files are in `.gitignore`. Back the keystore up: losing it means users can
never update the app in place. An APK signed with the debug key cannot be
updated by one signed with the release key (Android reports a signature
mismatch); uninstall once, then install the signed build.

### Dependency lockfile

`pubspec.lock` is generated by `flutter pub get` and is not committed. Mawjac is
built in CI from the version ranges in `pubspec.yaml`; there is no local Flutter
installation in the development environment. If you need reproducible builds,
commit the lockfile from a machine that has the pinned SDK.

## Troubleshooting

- **`flutter: command not found`** — run `tool/bootstrap.sh`, or add
  `./.flutter/bin` to `PATH`.
- **Linux build cannot find GTK** — install `libgtk-3-dev` and `pkg-config`.
- **`libmpv.so` missing at runtime** — install `libmpv2`/`libmpv1` (or
  `mpv-libs`). The AppImage does not include libmpv.
- **`flutter create` fails with an existing project name** — bootstrap creates
  the template in a temporary directory, so this usually means `--project-name`
  or the pinned SDK changed; remove the generated `android/`/`linux/` folders
  and rerun.
- **ARM64 job is skipped** — the repository is private; use a self-hosted ARM64
  runner or build the packages manually.
- **Android build fails on SDK licenses** — run
  `flutter doctor --android-licenses` locally, or add the license acceptance
  step to your own CI.
