# Ashcrown — Android debug APK install

**APK:** `ashcrown-debug.apk` (same folder as this file)  
**Package ID:** `com.diddy674176.ashcrown`  
**Version:** 0.1.0 (versionCode 1)  
**ABI:** arm64-v8a (modern phones)  
**Min SDK:** 21 · **Target SDK:** 34  
**Signing:** Android debug keystore (dev only — not Play Store)

## Install on phone

1. Copy `ashcrown-debug.apk` to your phone (USB, Drive, email, etc.).
2. On Android: **Settings → Security** (or **Apps → Special access**) → enable **Install unknown apps** / **Unknown sources** for the app you use to open the APK (Files, Chrome, Drive, …).
3. Open the APK file → tap **Install**.
4. If Android blocks it as “unsafe”, tap **Install anyway** / **More details** (debug builds are not Play-signed).
5. Launch **Ashcrown**.

Uninstall later from Settings → Apps → Ashcrown, or long-press the icon.

## Rebuild locally (Godot 4.3)

Prerequisites:
- Godot **4.3.stable**
- Export templates for 4.3 (`Editor → Manage Export Templates`, or unpack `.tpz` into `~/.local/share/godot/export_templates/4.3.stable/`)
- JDK 17+ (`JAVA_HOME`)
- Android SDK with `platform-tools`, `build-tools;34.0.0` (or 35), `platforms;android-34`
- Debug keystore (Godot creates one at `~/.local/share/godot/keystores/debug.keystore` with alias `androiddebugkey` / password `android`)

Editor settings (Editor → Editor Settings → Export → Android):
- Java SDK path
- Android SDK path

From project root:

```bash
mkdir -p build
godot --headless --path . --export-debug "Android" build/ashcrown-debug.apk
```

Or release-unsigned style (still uses release template; prefer debug for sideload):

```bash
godot --headless --path . --export-release "Android" build/ashcrown-release.apk
```

Preset: `export_presets.cfg` → preset **"Android"**  
(`gradle_build/use_gradle_build=false`, package `com.diddy674176.ashcrown`)

**Never commit** `*.keystore`, `*.jks`, or keystore passwords.
