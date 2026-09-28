# Ashcrown — Phase 1 Foundation

## What's here
- `project.godot` — Godot 4.3+, Forward Mobile renderer, autoloads EventBus + SaveManager
- `Main/Main.tscn` — Emberveil Reach + player + touch + chunk streamer
- `Character/PlayerController.gd` — walk/run/jump, touch stick + orbit + pinch/zoom
- `UI/TouchControls.tscn` — stick, look zone, ATK / DODGE / S1 / S2 / JUMP / USE
- `World/GrayboxRegion.gd` — **Emberveil Reach** landmarks (Ashfen Gate, Wilds, Coilcrypt, waystone)
- `Save/SaveManager.gd` — JSON autosave, corruption-safe write
- `Streaming/ChunkStreamer.gd` — neighbor chunk marker stub
- Data stubs: `Character/Attributes.gd`, `StarterKits.gd`, `Combat/CoilWardenStub.gd`, `AFK/AfkProfiles.gd`
- `export_presets.cfg` — Android/iOS stubs (signing TBD)

## Run
Open folder in Godot 4.3+ → Play (`Main/Main.tscn`).

## Exit
Walk Emberveil Reach graybox with save/load on device/emulator.
