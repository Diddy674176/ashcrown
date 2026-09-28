# Ashcrown — First Playable (§82 Vertical Slice)

**Definition of done:** A stranger can install a build, create a character, play ~30–60 minutes, clear the boss, try AFK, close the app, reopen to a truthful offline report — on a mid-range phone or equivalent emulator — without critical blockers.

Engine: **Godot 4**. Do not expand to multi-region content until this list is green.

---

## Content checklist

- [ ] **One beautiful open-world region** (streamed, LOD'd)
- [ ] **One town** (vendors, quest givers, day/night schedules for key NPCs)
- [ ] **One wilderness zone** (traversal, camps, resources)
- [ ] **One dungeon** (authored layout, readable loop)
- [ ] **Several enemy types** (≥3) with distinct roles
- [ ] **One major boss** (phases + unique loot)
- [ ] **One companion** (recruit, gear stub, combat role, AFK-capable)
- [ ] **Small quest chain** (context, named NPCs, choice + consequence flag)
- [ ] **Equipment + loot** (tiers working; compare/equip)
- [ ] **Crafting** (at least smith + one consumable craft; queue tick for AFK)

---

## Systems checklist

- [ ] **Mobile controls** remappable; documented default layout
- [ ] **Manual combat** responsive (light/heavy/dodge/skill)
- [ ] **Auto combat** uses telegraphs + heal rules (not dumb mash)
- [ ] **AFK farming** with at least 3 profiles + custom rules
- [ ] **Offline progression** + **return report** UI
- [ ] **Save/load** (autosave, resume after kill)
- [ ] **Performance settings** (presets wired to real quality toggles)

---

## Feel / quality gates

- [ ] First 15 minutes: hook → creation → combat → loot upgrade → open-world beat → companion or NPC → AFK intro
- [ ] No fake buttons: every HUD entry either works or is hidden
- [ ] Mid preset hits FPS target on reference device
- [ ] Battery Saver visibly reduces cost
- [ ] Known issues listed; no silent crashes on suspend/resume

---

## Explicitly NOT required for First Playable

Kingdom wars, raids, seasons, MMO multiplayer, full mount roster, housing mansion tree, sailing, New Game+, mythic tiers, full procedural quest language.

---

## Sign-off

| Role | Signs when |
|------|------------|
| Creative Director | Tone, region fantasy, boss fantasy coherent |
| Game Designer | Loop fun; progression readable |
| AFK AI Designer | Agent + offline report trustworthy |
| Combat Designer | Manual + auto combat pass |
| Godot Engineer | Build runs; budgets held |
| Bob (owner) | Would show a friend |

---

## NEXT after green

Phase 5 world expansion → more regions/factions/events — still Godot 4 mobile budgets.
