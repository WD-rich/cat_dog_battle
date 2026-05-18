# Export Notes

This project targets Godot 4.6.x with GDScript.

## Local Play

Open:

```text
/Users/wd/games/cat_dog_battle/project.godot
```

Run the main scene:

```text
res://scenes/Main.tscn
```

## Web

Godot 4 Web export supports GDScript projects. This project already uses the Compatibility renderer, which is the correct renderer family for Web export.

First-version Web build command:

```bash
bash tools/export_web.sh
python3 -m http.server 8765 --bind 127.0.0.1 --directory builds/web
```

Then open:

```text
http://127.0.0.1:8765
```

The generated files live under:

```text
builds/web/index.html
```

Do not open the exported HTML through `file://`; use a small local server instead.

Editor export steps:

1. Open Godot.
2. Install export templates if Godot asks for them.
3. Open `Project -> Export`.
4. Add a `Web` preset.
5. Set the output file to `builds/web/index.html`.
6. Disable threaded export unless the hosting server is configured for cross-origin isolation.
7. Export and serve the folder through a local or remote web server.

## Android

Android export requires:

- Godot export templates.
- Android SDK.
- JDK 17 or a compatible JDK.

Basic steps:

1. Install or open Android Studio once so the Android SDK is available.
2. In Godot, open `Editor Settings -> Export -> Android`.
3. Point Godot to the Android SDK and JDK.
4. Open `Project -> Export`.
5. Add an `Android` preset.
6. Export an APK for device testing.

Android/mobile touch controls are intentionally hidden in the current Web-first prototype. Re-enable and polish touch controls before exporting a real mobile build.
