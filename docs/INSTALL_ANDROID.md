# Ashcrown — Android debug APK install

**APK:** `ashcrown-debug.apk` (same folder as this file)  
**Package ID:** `com.diddy674176.ashcrown`  
**Version:** 0.2.1 (versionCode 4)  
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

```bash
mkdir -p build
godot --headless --path . --export-debug "Android" build/ashcrown-debug.apk
cp -f build/ashcrown-debug.apk export/ashcrown-debug.apk
```

Preset: `export_presets.cfg` → **"Android"** · package `com.diddy674176.ashcrown`  
**Never commit** `*.keystore`, `*.jks`, or keystore passwords.
