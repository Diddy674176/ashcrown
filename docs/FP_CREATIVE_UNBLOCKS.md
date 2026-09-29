# Ashcrown — First Playable Creative Unblocks

**Owner:** Creative Director (coordination) · **Implementation:** Godot Engineer  
**Bar (Bob / The Man):** Not graybox alone — combat + Coil Warden + AFK return report **playable on device**, then ping Bob.  
**Region lock:** Emberveil Reach only.

---

## Creative DONE (do not wait on CD)

| Doc | Unlocks |
|-----|---------|
| `TONE.md` | Ember/legacy art & copy bar |
| `CREATIVE_FIRST_PLAYABLE.md` | Naming sheet, beat sheet, locks |
| `BOSS_COIL_WARDEN.md` | 3-phase fantasy + Wake/Aether lean + drop |
| `WORLD_FIRST_PLAYABLE.md` | Region layout + quest pins |
| `WORLD_POI_BRIEF.md` | Landmark art/gameplay one-pagers |
| `AFK_REPORT_VOICE.md` | Return report strings + stop reasons |
| `COMBAT.md` (Combat Designer) | Feel, telegraphs, modes |
| `AFK_AGENT.md` (AFK AI Designer) | Profiles, offline, report schema |

---

## Build priority (Godot Engineer) — stall killers first

### P0 — device-playable gates (must all be green before Bob ping)

1. **Manual combat** — light/heavy/dodge/block/skills; Vein-mite + bruiser + caster (or clear stubs with distinct roles); heat gates ult spam.  
2. **Coil Warden** — 3 phases per `BOSS_COIL_WARDEN.md` + Combat frame data; unique drop Circlet Fragment; telegraphs amber/blue-white/red, silhouette-readable.  
3. **AFK return report** — ≥3 profiles (EXP/Gold/Explore/Balanced per AFK_AGENT); offline or foreground session → truthful report UI using `AFK_REPORT_VOICE.md`.

### P1 — same slice, unlocks “would show a friend”

4. Ashfen Gate vendors + Len quest beat 1–2 + Ember Camp AFK radius.  
5. Auto/assisted combat sharing decision hooks.  
6. Rook companion stub in combat + AFK.  
7. Performance Mid preset + Battery Saver visible.

### P2 — after green P0

Quest choice dig/seal, full dungeon loop polish, crafting queue, remappable controls.

---

## CD will not block on

New regions, full Ashcrown relic, kingdom wars, art finalization beyond readable graybox+silhouette+telegraph colors, cloud AFK.

---

## Sign-off path

| Role | When |
|------|------|
| Godot Engineer | Build runs on device; P0 green |
| Combat Designer | Manual + Warden feel pass |
| AFK AI Designer | Report trustworthy vs schema |
| Creative Director | Tone + boss + report voice coherent |
| Bob | Would show a friend — **ping only when P0 green** |

---

*CD coordination sheet — update checkboxes in FIRST_PLAYABLE.md as eng lands systems.*
