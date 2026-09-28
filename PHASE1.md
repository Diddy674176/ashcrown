# Phase 1 — Foundation

Local Godot 4.3 project under `/workspace/ashcrown` (this repo).

## Done

- [x] `project.godot` — Forward Mobile renderer, touch emulation, physics 30 Hz
- [x] `Main/Main.tscn` + `Main.gd` — entry: Emberveil Reach + player + touch HUD
- [x] `Character/Player.tscn` — controller stub (walk/sprint/jump) + camera pivot
- [x] `UI/TouchControls.tscn` — virtual stick + look + action cluster
- [x] `Save/SaveManager.gd` — autoload, corruption-safe JSON autosave
- [x] `World/EmberveilReach/` — graybox region + Ashfen Gate stub
- [x] `World/GrayboxRegion.tscn` — CSG graybox helper
- [x] `export_presets.cfg` — Android/iOS stubs (signing TBD, never commit secrets)

## Run

```bash
godot4 --path .
# box: /workspace/tools/godot --path /workspace/ashcrown
```

## Blockers for The Man

- Export signing keystores not created (intentional).
- Headless validation may warn on dummy mesh / transform before tree enter — non-blocking on desktop/GPU.
- Cloud Agents unavailable — continue on box + this repo only.

## NEXT

Phase 2 combat stubs; flesh Emberveil Reach toward First Playable (§82).
