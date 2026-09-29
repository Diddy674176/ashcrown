# Ashcrown — Creative Director Pack (First Playable)

**Owner:** Creative Director  
**Status:** LOCKED — grind targets for studio  
**Scope:** §82 vertical slice only (one region)  
**Canonical docs:** `/workspace/ashcrown-docs/` · repo https://github.com/Diddy674176/ashcrown

---

## 1. Locks (do not reopen without Bob)

| Lock | Decision |
|------|----------|
| Title | **Ashcrown** (not Aetherwake / Ashen Crown) |
| Engine | Godot 4, mobile-first |
| Tone | Ember / legacy — see `TONE.md` |
| Region | **Emberveil Reach** |
| Town | **Ashfen Gate** |
| Wilderness | Emberveil Wilds (Wake-Pit → Aetherwood → Vein Marsh → Heat-sink Scar) |
| Dungeon | **Coilcrypt** |
| Boss | **The Coil Warden** (2–3 phases; drop **Ash-etched Circlet Fragment**) |
| Companion | **Rook** |
| Rivalry flag | `scar_excavated` vs `scar_sealed` (one consequence, no kingdom war) |

---

## 2. Creative pillars for this slice

1. **Dusk after fire** — every art and VO pass must pass the TONE.md feeling test.
2. **World that remembers** — named NPCs quote one player choice in one sentence.
3. **Agent, not idle** — AFK report and camp fantasy feel like a Waker’s trusted second, not a clicker.
4. **One beautiful region** — depth over sprawl; Mid-preset silhouettes win.

---

## 3. Studio deliverables (Creative coordination)

| Owner | Deliverable for First Playable | Done when |
|-------|--------------------------------|-----------|
| **Creative Director** | Tone bible + region/boss fantasy lock | This pack + `TONE.md` |
| **World Builder** | POI art/gameplay one-pagers (`WORLD_POI_BRIEF.md`) | 4 landmarks + town districts briefed |
| **Game Designer** | Quest timing, levels, choice consequence readable | Spine 1–6 playable in 30–60 min |
| **Combat Designer** | Coil Warden phases + telegraph pass; enemy roles feel distinct | Manual + auto pass on Mid |
| **AFK AI Designer** | Ember Camp safe radius + offline report copy tone | Report feels like field log |
| **Godot Engineer** | Chunk scheme, dungeon scene split, empty scenes named to locks | Scaffold matches names above |

**Bob sign-off:** Would show a friend the Emberveil fantasy and boss drop tease.

---

## 4. First 15 minutes (creative beat sheet)

| Beat | Place | Fantasy hit |
|------|-------|-------------|
| Hook | Starter Wake-Pit | Climb from collapsed conduit — ash-light wake |
| Hub | Ashfen Gate | Warm lamps, Concord charter, ember/legacy UI |
| Combat + loot | Aetherwood / Ember Camp | Readable enemies; first upgrade dopamine |
| Open-world | Singing Root silhouette | Dual nature (tree + crystal veins) |
| Companion or NPC | Rook / Cald / Len | Someone remembers you |
| AFK intro | Sera + Ember Camp | Agent with rules, not a dumb toggle |
| Cap (same session or next) | Coilcrypt → Coil Warden | Binding-wrong boss; circlet fragment tease |

---

## 5. Boss fantasy (CD brief for Combat)

**Full lock:** [`BOSS_COIL_WARDEN.md`](BOSS_COIL_WARDEN.md) — aligned to Combat’s 2–3 phase template.

**The Coil Warden** — Wake-primary guardian fused to a buried battery coil; Aether bleed as arena wound. Choirbound: a wound. Wakewrights: an engine gone wrong.

| Phase | Combat template | Fantasy |
|-------|-----------------|--------|
| 1 | Learn 2–3 tells | **Coil sentinel** — amber/blue-white teaching tells |
| 2 | Unblockable or arena hazard | **Bleed surge** — Aether vents + red coil overload |
| 3 | Enrage / poise windows | **Crown echo** — ash-light motif; poise finish |

**Lean:** Wake body · Aether hazards · ash-light finale. **Drop:** Ash-etched Circlet Fragment. Telegraph colors: Combat amber / blue-white / red — no conflict.

---

## 6. Naming sheet (frozen for scaffold)

```
Region:     Emberveil Reach
Town:       Ashfen Gate
Wilds:      Emberveil Wilds
Landmark:   The Singing Root
Landmark:   Gray Concord waystone
Dungeon:    Coilcrypt
Boss:       The Coil Warden
Loot tease: Ash-etched Circlet Fragment
Companion:  Rook
```

Godot scenes/folders should match these strings so docs and project stay aligned.

---

## 7. Explicitly out of creative scope (slice)

Other regions, floating isles as playable, Corehold politics deep dive, sailing, kingdom wars, full Ashcrown relic acquisition, meme marketing tone, Aetherwake rename leftovers.

---

## 8. NEXT

1. ~~World Builder: `WORLD_POI_BRIEF.md`~~ DONE (`WORLD_POI_BRIEF.md`).  
2. ~~Combat / CD Coil Warden lock~~ DONE (`BOSS_COIL_WARDEN.md`).  
3. AFK report voice DONE (`AFK_REPORT_VOICE.md`).  
4. **Godot Engineer:** implement P0 in `FP_CREATIVE_UNBLOCKS.md` (combat + Warden + AFK report on device) — then studio pings Bob.  
5. CD: review device builds against `TONE.md` feeling test before Bob ping.

---

*Creative Director — Ashcrown studio · First Playable grind pack*
