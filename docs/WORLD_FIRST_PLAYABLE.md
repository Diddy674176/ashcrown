# Ashcrown — First Playable World Package

**Owner:** World Builder  
**Scope:** One streamed region for §2 vertical slice — town + wilderness + dungeon  
**Coherence:** DESIGN_BIBLE.md tone + magic; SYSTEMS.md living-world LOD; PERFORMANCE_BUDGET.md streaming  
**Status:** LOCKED by Creative Director (Emberveil Reach) — iterate POIs, do not swap region without Bob

**Do not use:** Aetherwake branding or multi-region sprawl until First Playable is green.

---

## 1. Region lock (proposed)

| Field | Value |
|-------|--------|
| **Name** | **Emberveil Reach** |
| **Fantasy** | Dusk forest cut by bioluminescent **Aether veins** and buried **Wake conduits**; ash-gold canopy, ember undergrowth, crystalline roots that hum at night |
| **Why this slice** | Contiguous land (easy mobile streaming), dual fantasy in one glance (living trees + metal glyphs), natural day/night spawn shifts, readable silhouette landmarks |
| **Approx playable footprint** | ~1.2–1.8 km traversable diameter (authored POIs dense; filler LOD’d) |
| **Biome mix** | Primary: Aetherwood. Secondary: Vein marsh (wet, conductive). Tertiary stub: Heat-sink scar (small ruin strip toward dungeon) |
| **Climate** | Cool dusk light most of day; brief clear noon; fog in vein marsh at dawn |

**Alternates (if CD rejects):**  
- **Corehold Marches** — castle town over an orbital battery Core (more urban/faction politics).  
- **Sandglass Verge** — desert of sandglass + heat-sink ruins (harsher traversal, stronger Wake-ruin fantasy).

---

## 2. Spatial layout (authored)

Think a soft triangle the player can cross in active play in ~8–12 minutes walk (mid mountless speed), with AFK pathing using the same nav mesh.

```
                    [NORTH — Heat-sink Scar]
                           |
                    DUNGEON: Coilcrypt
                           |
         [Vein Marsh] ---- Crossroads ---- [Aetherwood Ridge]
                           |
                    TOWN: Ashfen Gate
                           |
                    [SOUTH — starter wake-pit / tutorial pocket]
```

### Chunk / streaming intent
- **Town chunk** always resident while inside walls + 1 ring.
- **Wilderness** in 256–512 m chunks; keep ≤2–3 hot chunks + town.
- **Dungeon** separate streamed scene (load gate at Coilcrypt mouth); unload wilderness deep inside.
- Distant town = HLOD silhouette + smoke column; no full NPC sim.

### Landmark silhouettes (must read at Mid preset)
1. **Ashfen Gate spire** — Wake-etched watchtower + manuscript banners (town).
2. **The Singing Root** — giant crystal-veined tree on the ridge (wilderness hub / gather).
3. **Coilcrypt mouth** — circular heat-sink ring in the scar, orange night glow (dungeon).
4. **Gray Concord waystone** — crossroads pillar (fast travel stub / quest pin).

---

## 3. Town — Ashfen Gate

**Role:** Safe hub, vendors, quest spine, day/night NPC schedules, faction face.

**Faction lean:** **Gray Concord** free-city charter; Wakewright workshop tolerated inside walls; Choirbound shrine just outside east gate (tension without open war).

### Districts (tiny — keep walkable)
| District | Contents |
|----------|----------|
| **Gate Yard** | Stables stub, bounty board, Concord guards, return-from-AFK report kiosk flavor |
| **Market Ring** | General vendor, smith (craft), alchemy stall, salvage buyer |
| **Lower Quarters** | Inn, companion recruit spot, player stash/chest |
| **Concord Hall** | Quest givers (Magistrate Len, Archivist Sera), rumor board |
| **East Shrine Path** | Choirbound presence (Sister Cald) — prices/dialogue shift with reputation |

### Key NPCs (schedules — L0 when nearby)
| NPC | Day | Night | Notes |
|-----|-----|-------|-------|
| Magistrate Len | Concord Hall | House (offline) | Main quest chain |
| Archivist Sera | Hall → Market | Hall lamp-lit | Lore + map unlocks |
| Smith Brann | Forge | Forge (tired dialog) | Craft queue + gear compare |
| Sister Cald | East shrine | Vigil at Singing Root path | Choirbound lean; memory flag if helped/ignored |
| Rook (companion) | Inn yard | Inn | Recruit after quest beat 2 |
| Guard captain Vos | Gate Yard | Wall patrol | Danger tips / bounty |

### Town living-world hooks (slice)
- Day/night shop hours (alchemy closes late; smith stays open).
- One rivalry flag: **Wakewright vs Choirbound** shifts smith prices ± and unlocks one alternate quest beat.
- Memory flags: `saved_ashfen_patrol`, `helped_cald`, `ignored_scar_alarm`.

---

## 4. Wilderness — Emberveil Wilds

**Role:** Traversal, camps, resources, 3+ enemy roles, open-world beat for first 15 minutes.

### Zones
| Zone | Fantasy | Gameplay |
|------|---------|----------|
| **Starter Wake-Pit** | Collapsed conduit the player climbs from | Tutorial combat + first loot; no return needed |
| **Aetherwood** | Forest + glowing veins | Main roam; gather fiber/ore nodes; camps |
| **Vein Marsh** | Wet conductive flats | Slower move, shock flora, rare Binding reagents |
| **Heat-sink Scar** | Ash + metal ribs toward dungeon | Higher level trash; boss approach road |

### Camps & POIs
- **Ember Camp** — rest, craft tick stub, AFK safe radius.
- **Wakewright Survey Tent** — optional EXP/Gold profile tip + small bounty.
- **Abandoned Choir Chapel** — secret (active-play bias); lore note + minor artifact.
- **Resource rings:** sap-crystal (Focus craft), ash-iron (smith), glowcap (alchemy).

### Enemy roles (≥3 for slice)
| Role | Example | Where |
|------|---------|-------|
| **Trash skirmisher** | Vein-mite swarm | Aetherwood |
| **Bruiser** | Wake-warped stag | Ridge / camps |
| **Ranged / hazard** | Conduit wisp | Marsh + scar |
| *(optional 4th)* | Concord deserter bandit | Crossroads at night |

Weather/day: fog boosts wisp spawns; night increases scar patrol density lightly.

---

## 5. Dungeon — Coilcrypt

**Role:** Authored loop, readable, one major boss, unique loot. Load as own scene.

### Fantasy
A buried **Wake battery coil** under the Heat-sink Scar. Choirbound call it a wound; Wakewrights call it a Core-adjacent engine. Something inside is **binding wrong** — Wake-warped guardian feeding on Aether bleed.

### Layout loop (single floor + boss annex)
1. **Mouth** — safe camp, lore tablet, return teleport stub after clear.
2. **Outer ring** — clockwise patrol loop; teach telegraphs on conduit sentries.
3. **Bleed gallery** — vertical aether falls; platform/traversal beat (mobile-friendly; no precision parkour).
4. **Bind chamber** — elite + puzzle-lite (align 3 Wake glyphs — AFK can skip with key drop from elite).
5. **Boss annex — The Coil Warden** — 2–3 phases (see combat owner); unique drop **Ash-etched Circlet Fragment** (build tease, not full Ashcrown).

**AFK:** Dungeon profile allowed after first clear or with companion; stop on wipe / inventory full / rule retreat.

---

## 6. Factions (slice set)

| Faction | Stance in Emberveil | Player-facing |
|---------|---------------------|---------------|
| **Gray Concord** | Runs Ashfen Gate | Main quest employer; “peace through ledger and guard” |
| **Wakewrights** | Survey tent + forge contracts | Craft discounts; EXP/tech bounties; cold pragmatism |
| **Choirbound** | East shrine + chapel ruin | Nature/Light lean; warn against Core rupture; Reputation path |
| **Unbound / scar threats** | Coilcrypt + warped fauna | Not a joinable faction — pressure the region |

**Rivalry (one):** Concord mediates; player choice on a Wakewright dig vs Choirbound seal becomes the quest consequence flag (`scar_excavated` vs `scar_sealed`) — changes Coilcrypt intro VO and one vendor line. No kingdom war.

---

## 7. Quest spine (world-facing)

Owned with Quests/Game Design — world pins only:

1. **Wake** — climb Wake-Pit → Ashfen Gate (hook).  
2. **Charter** — Len: clear Ember Camp threat → unlock wilderness AFK radius.  
3. **Companion** — Rook joins after camp clear.  
4. **Scar Alarm** — choose dig vs seal (consequence).  
5. **Coilcrypt** — clear Coil Warden → fragment + region “stabilized” memory.  
6. **AFK intro** — Sera teaches profiles using Ember Camp farm.

---

## 8. Living-world sim LOD (design now)

| LOD | When | What simulates |
|-----|------|----------------|
| **L0** | Near player / town when present | Full NPC schedules, combat AI, gather nodes refresh |
| **L1** | Adjacent chunks | Simplified spawns; vendors static; no full pathing crowds |
| **L2** | Rest of Emberveil while in dungeon/AFK offline | Abstract: camp threat level, vendor stock tick, rivalry pressure score |
| **L3** | App suspended / offline AFK | Statistical: kills, gather yields, quest progress caps from SYSTEMS offline rules |

**Slice implement order:** L0 town schedules + L3 offline first; L1/L2 stubs as counters the AFK report can cite (“Ashfen patrol losses: 0”).

---

## 9. Procedural-history hooks (data, not generators yet)

Keep as **flag + bark** tables the living world and quests read — not a full proc-gen language.

| Hook ID | Set by | Referenced by |
|---------|--------|---------------|
| `player_woke_in_reach` | Character create | Len, Sera first meeting |
| `ember_camp_cleared` | Quest 2 | Vos, AFK safe radius |
| `rook_recruited` | Quest 3 | Inn / combat |
| `scar_excavated` / `scar_sealed` | Quest 4 choice | Coilcrypt VO, Cald/Brann prices |
| `coil_warden_slain` | Boss clear | Town celebration bark; scar spawn calm |
| `ignored_scar_alarm` | Timeout / skip | Cald cold line; higher night bandit weight |

History is **durable and quotable** — NPCs name the player’s choice in one sentence, not a wiki dump.

---

## 10. Mobile / streaming checklist (world)

- [ ] Chunk size + resident caps documented with Godot Engineer  
- [ ] Town HLOD + 4 silhouette landmarks readable Mid preset  
- [ ] Dungeon own scene; wilderness unload deep inside  
- [ ] Gather nodes pooled; no per-node scripts at L1+  
- [ ] NPC count: ≤12 named schedule actors; crowd = impostors/deco  
- [ ] Night lights budget: town warm lamps + vein glow + Coilcrypt mouth only  

---

## 11. Out of scope (explicit)

Other continents, floating Anchor Isles as playable, full Corehold politics, sailing, kingdom wars, housing lots, multi-dungeon proc language, thousands of NPCs.

---

## 12. Sign-off & NEXT

| Role | Needs |
|------|--------|
| Creative Director | DONE — Emberveil locked (`TONE.md`, `CREATIVE_FIRST_PLAYABLE.md`) |
| World Builder | Iterate layout after lock; POI art briefs |
| Game Designer | Quest timing + enemy levels |
| AFK AI Designer | Camp safe radius + offline L3 inputs |
| Godot Engineer | Chunk scheme + dungeon scene split |
| Bob | “Would show a friend” region fantasy |

**NEXT (post CD lock):**  
1. ~~Freeze Emberveil~~ DONE.  
2. Write `WORLD_POI_BRIEF.md` (per-landmark art/gameplay one-pagers).  
3. Hand chunk map sketch + naming sheet to Godot scaffold (`CREATIVE_FIRST_PLAYABLE.md` §6).  
4. Align enemy/boss names with Combat Designer (Coil Warden fantasy locked).

