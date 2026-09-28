# Ashcrown — Roadmap

Engine: **Godot 4** · Mobile-first · First Playable = brief **§82** vertical slice  
Repo: https://github.com/Diddy674176/ashcrown

Phases mirror source brief §81. Do not expand content massively until First Playable is genuinely playable.

---

## Phase 1 — Foundation
- Godot 4 project setup (Android/iOS export presets)
- Character controller + camera
- Mobile touch controls (stick, camera swipe, attack/skills/dodge/jump/interact)
- Save/load (autosave, corruption-safe)
- Basic world streaming / chunk load for one region

**Exit:** Walk a small open space on device/emulator with save/load.

## Phase 2 — Combat
- Light/heavy/charged attacks, dodge, block/parry stubs
- 3+ enemy types + AI basics
- Skills + stamina/focus
- Loot drops
- One major boss (multi-phase light)

**Exit:** Manual combat feels responsive; one boss clearable.

## Phase 3 — RPG
- Inventory, attributes, equipment
- Classless skill unlock stubs
- NPC interaction + dialogue
- Small authored quest chain

**Exit:** Equip upgrades change power; quest completes with consequence flag.

## Phase 4 — AFK
- Navigation agent + combat agent
- Loot automation + goal/priority system
- AFK profiles + rule set
- Offline progression simulation + return report

**Exit:** Leave AFK 10+ minutes (or offline sim) and get a truthful report.

## Phase 5 — World
- Multi-biome region expansion (still one continent slice)
- Factions + reputation
- World events (lite)
- Economy stubs + NPC schedule LOD

**Exit:** World changes while player is elsewhere (sim LOD).

## Phase 6 — Expansion systems
- Crafting queues
- Companions (beyond the first)
- Housing lite
- Authored + modular dungeons
- Mounts

## Phase 7 — Kingdom
- Settlements, territory, trade, wars (AFK-manageable)

## Phase 8 — Polish
- Graphics presets, animation, audio, UI, deep optimization, accessibility

## Phase 9 — Endgame
- Raids, mythic bosses, world tiers, seasonal optional content

---

## First Playable gate (§82)

See `FIRST_PLAYABLE.md`. **No Phase 5+ content sprawl** until that checklist is green.

## Priority order (always)

1. Fun  
2. Stability  
3. Mobile performance  
4. Intelligent AFK  
5. Deep progression  
6. Living-world sim  
7. Content variety  
8. Visual quality  
9. Replayability  
10. Extensibility  

---

## NEXT

1. Design docs (Ashcrown brand)  
2. Studio bots + Ashcrown channel  
3. Docs committed to https://github.com/Diddy674176/ashcrown  
4. **Godot 4 project scaffold** (Phase 1 foundation)
