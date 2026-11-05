#!/usr/bin/env python3
"""Applies Mawjac-specific settings to Flutter's generated platform shells.

Everything here is idempotent: bootstrap.sh may be rerun on an existing
checkout without duplicating permissions or icons.
"""

from __future__ import annotations

import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANDROID = ROOT / "android"
LINUX = ROOT / "linux"
BRANDING = ROOT / "assets" / "branding"

APP_ID = "com.mmbesar.mawjac"
APP_LABEL = "Mawjac"

PERMISSIONS = (
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.WAKE_LOCK",
)

DESKTOP_FILE = """[Desktop Entry]
Type=Application
Name=Mawjac
GenericName=IPTV Client
Comment=Bidirectional IPTV client with a 12-hour guide
Exec=mawjac
Icon=mawjac
Terminal=false
Categories=AudioVideo;Video;Player;TV;
Keywords=iptv;m3u;xmltv;tv;stream;
StartupWMClass=com.mmbesar.mawjac
"""


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def patch_android_manifest() -> None:
    manifest = ANDROID / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest.exists():
        print("  AndroidManifest.xml not found; skipping")
        return

    text = read(manifest)
    missing = [
        permission for permission in PERMISSIONS if permission not in text
    ]
    if missing:
        lines = "".join(
            f'    <uses-permission android:name="{permission}" />\n'
            for permission in missing
        )
        match = re.search(r"<manifest\b[^>]*>", text)
        if not match:
            raise SystemExit("Could not find the <manifest> element")
        text = text[: match.end()] + "\n" + lines + text[match.end() :]

    if "usesCleartextTraffic" not in text:
        text = re.sub(
            r"<application\b",
            '<application\n        android:usesCleartextTraffic="true"',
            text,
            count=1,
        )

    if "supportsPictureInPicture" not in text:
        text = re.sub(
            r"<activity\b",
            '<activity\n            android:supportsPictureInPicture="true"',
            text,
            count=1,
        )

    text = re.sub(
        r'android:label="[^"]*"',
        f'android:label="{APP_LABEL}"',
        text,
        count=1,
    )
    write(manifest, text)
    print("  patched AndroidManifest.xml")


MAIN_ACTIVITY = """package com.mmbesar.mawjac

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Picture-in-picture for the player: Dart asks to float the video, and
// (optionally) the window floats by itself when the user leaves the app.
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var autoEnter = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val pip = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mawjac/pip")
        channel = pip
        pip.setMethodCallHandler { call, result ->
            when (call.method) {
                "enter" -> result.success(enterPip())
                "autoEnter" -> {
                    autoEnter = call.arguments as? Boolean ?: false
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enterPip(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return false
        }
        return try {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            enterPictureInPictureMode(params)
        } catch (e: Exception) {
            false
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (autoEnter) {
            enterPip()
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode)
        channel?.invokeMethod("pip", isInPictureInPictureMode)
    }
}
"""


def patch_android_activity() -> None:
    kotlin = ANDROID / "app" / "src" / "main" / "kotlin" / "com" / "mmbesar" / "mawjac"
    if not (ANDROID / "app" / "src" / "main").is_dir():
        print("  android sources not found; skipping MainActivity")
        return
    target = kotlin / "MainActivity.kt"
    if target.exists() and read(target) == MAIN_ACTIVITY:
        return
    write(target, MAIN_ACTIVITY)
    print("  wrote MainActivity.kt (picture-in-picture)")


KTS_HEAD = """import java.io.FileInputStream
import java.util.Properties

"""

KTS_PROPS = """val mawjacKeyProps = Properties()
val mawjacKeyFile = rootProject.file("key.properties")
if (mawjacKeyFile.exists()) {
    FileInputStream(mawjacKeyFile).use { mawjacKeyProps.load(it) }
}

"""

KTS_SIGNING = """    signingConfigs {
        create("release") {
            if (mawjacKeyFile.exists()) {
                keyAlias = mawjacKeyProps["keyAlias"] as String
                keyPassword = mawjacKeyProps["keyPassword"] as String
                storeFile = rootProject.file(mawjacKeyProps["storeFile"] as String)
                storePassword = mawjacKeyProps["storePassword"] as String
            }
        }
    }

"""

GROOVY_PROPS = """def mawjacKeyProps = new Properties()
def mawjacKeyFile = rootProject.file("key.properties")
if (mawjacKeyFile.exists()) {
    mawjacKeyFile.withInputStream { mawjacKeyProps.load(it) }
}

"""

GROOVY_SIGNING = """    signingConfigs {
        release {
            if (mawjacKeyFile.exists()) {
                keyAlias mawjacKeyProps['keyAlias']
                keyPassword mawjacKeyProps['keyPassword']
                storeFile rootProject.file(mawjacKeyProps['storeFile'])
                storePassword mawjacKeyProps['storePassword']
            }
        }
    }

"""


def sign_kts(text: str) -> str:
    """Release builds use android/key.properties when present, else debug."""
    if "mawjacKeyProps" in text:
        return text
    text = KTS_HEAD + text
    text = re.sub(r"^android\s*\{", lambda m: KTS_PROPS + "android {", text, count=1, flags=re.M)
    text = re.sub(r"^(\s*)buildTypes\s*\{", lambda m: KTS_SIGNING + m.group(0), text, count=1, flags=re.M)
    text = re.sub(
        r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
        'signingConfig = if (mawjacKeyFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")',
        text,
    )
    return text


def sign_groovy(text: str) -> str:
    if "mawjacKeyProps" in text:
        return text
    text = re.sub(r"^android\s*\{", lambda m: GROOVY_PROPS + "android {", text, count=1, flags=re.M)
    text = re.sub(r"^(\s*)buildTypes\s*\{", lambda m: GROOVY_SIGNING + m.group(0), text, count=1, flags=re.M)
    text = re.sub(
        r"signingConfig\s+signingConfigs\.debug",
        "signingConfig mawjacKeyFile.exists() ? signingConfigs.release : signingConfigs.debug",
        text,
    )
    return text


def patch_android_gradle() -> None:
    kts = ANDROID / "app" / "build.gradle.kts"
    groovy = ANDROID / "app" / "build.gradle"
    if kts.exists():
        text = read(kts)
        text = re.sub(
            r'applicationId\s*=\s*"[^"]*"',
            f'applicationId = "{APP_ID}"',
            text,
        )
        text = re.sub(
            r"minSdk\s*=\s*(flutter\.minSdkVersion|\d+)",
            "minSdk = 24",
            text,
        )
        text = sign_kts(text)
        write(kts, text)
        print("  patched android/app/build.gradle.kts")
    elif groovy.exists():
        text = read(groovy)
        text = re.sub(
            r'applicationId\s+"[^"]*"',
            f'applicationId "{APP_ID}"',
            text,
        )
        text = re.sub(
            r"minSdkVersion\s+(flutter\.minSdkVersion|\d+)",
            "minSdkVersion 24",
            text,
        )
        text = sign_groovy(text)
        write(groovy, text)
        print("  patched android/app/build.gradle")


def patch_android_icons() -> None:
    source = BRANDING / "android"
    res = ANDROID / "app" / "src" / "main" / "res"
    if not source.is_dir() or not res.is_dir():
        print("  launcher icons not found; skipping")
        return

    for directory in sorted(source.iterdir()):
        if not directory.is_dir():
            continue
        destination = res / directory.name
        destination.mkdir(parents=True, exist_ok=True)
        shutil.copy2(directory / "ic_launcher.png", destination / "ic_launcher.png")

    # Flutter templates may ship adaptive icons that would hide our legacy
    # launcher PNGs on Android 8+. Remove them so every device uses Mawjac.
    for anydpi in res.glob("mipmap-anydpi*"):
        for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
            target = anydpi / name
            if target.exists():
                target.unlink()
    print("  installed Android launcher icons")


def patch_linux() -> None:
    cmake = LINUX / "CMakeLists.txt"
    if cmake.exists():
        text = read(cmake)
        text = re.sub(
            r'set\(APPLICATION_ID\s+"[^"]*"\)',
            f'set(APPLICATION_ID "{APP_ID}")',
            text,
        )
        write(cmake, text)
        print("  patched linux/CMakeLists.txt")

    runner = LINUX / "runner" / "my_application.cc"
    if runner.exists():
        text = read(runner)
        text = text.replace(
            'gtk_header_bar_set_title(header_bar, "mawjac");',
            'gtk_header_bar_set_title(header_bar, "Mawjac");',
        )
        text = text.replace(
            'gtk_window_set_title(window, "mawjac");',
            'gtk_window_set_title(window, "Mawjac");',
        )
        text = text.replace(
            "gtk_window_set_default_size(window, 1280, 720);",
            "gtk_window_set_default_size(window, 1280, 820);",
        )
        write(runner, text)
        print("  patched linux/runner/my_application.cc")


def write_desktop_entry() -> None:
    write(BRANDING / "mawjac.desktop", DESKTOP_FILE)


def main() -> int:
    if not ANDROID.is_dir() and not LINUX.is_dir():
        print("No generated platform directories found. Run tool/bootstrap.sh first.")
        return 1

    print("Configuring Mawjac platform shells:")
    patch_android_manifest()
    patch_android_activity()
    patch_android_gradle()
    patch_android_icons()
    patch_linux()
    write_desktop_entry()
    print("Platform configuration complete.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
