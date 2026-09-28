# Ashcrown — Combat Design (First Playable)

**Owner:** Combat Designer  
**Engine:** Godot 4 · Mobile-first  
**Scope:** Phase 2 + First Playable combat gates (`SYSTEMS.md` §1, `FIRST_PLAYABLE.md`)  
**Coordinate with:** AFK AI Designer (shared decision hooks), Game Designer (verbs ↔ progression), Creative Director (boss fantasy)

---

## 1. Goals

1. **Active play feels skillful** — light/heavy/dodge/skill timing matters; not a button mash.
2. **Auto is not dumb** — Assisted / Full auto / AFK combat share the same decision hooks (telegraphs, heal rules, heat caps).
3. **Readable on a phone** — telegraphs, silhouettes, and HUD survive small screens and thumbs.
4. **Fair AFK** — auto clears field trash and farm loops; mythic/boss skill expression still favors manual.
5. **Budget-aware** — limited simultaneous VFX, pooled projectiles, animation LOD (`PERFORMANCE_BUDGET.md`).

---

## 2. Combat modes (one brain, three drivers)

| Mode | Who drives | Notes |
|------|------------|--------|
| **Manual** | Player | Full skill expression; lock-on + free aim |
| **Assisted** | Player aim/move + agent skills | Agent respects player target + retreat rules |
| **Full auto** | Agent | Same hooks as AFK combat agent |

**Shared decision hooks** (must be callable by player input *and* AFK agent):

- `pick_target(threats, profile)` — highest utility (threat × distance × quest weight)
- `should_dodge(telegraph)` — if telegraph is dodgeable and timing window open
- `should_block(telegraph)` — if blockable and stamina allows
- `should_parry(telegraph)` — **Manual-only for MVP**; Assisted = OFF (uses block/dodge); Full auto uses safe block/dodge unless profile = Aggressive
- `should_heal(hp%, potions, rules)`
- `pick_skill(loadout, heat, cooldowns, target)` — never infinite ultimate (heat/cooldown)
- `should_retreat(hp%, level_gap, rules)`

AFK profiles bias utilities; they do not invent separate combat math.

---

## 3. Player verbs (slice)

| Verb | Input (default) | Feel |
|------|-----------------|------|
| Light | Tap attack | Fast, chaining, low poise damage |
| Heavy | Hold attack / heavy button | Slow, interruptible windup, high poise |
| Charged | Hold past heavy threshold | Telegraphed player windup; big payoff |
| Dodge | Dodge button | i-frames short; stamina cost; direction = move stick |
| Block | Hold block | Reduces damage; stamina drain vs heavy |
| Perfect block / parry | Block in window | Staggers attacker; Manual-favored |
| Skill 1–3 | Skill buttons | School-respecting costs (Focus + heat) |
| Ultimate | Ult button | High heat; long CD; AFK capped |
| Lock-on | Soft-lock default ON in combat | Free aim still allowed; tap swaps target; toggle can force unlock |
| Weapon swap | Swap | Brief vulnerability; AFK swaps only per profile rule |

**Attributes (GD-locked):** Might · Swift · Focus · Vitality · Binding — combat scales poise damage (Might), i-frame/timing forgiveness lightly (Swift), skill Focus pool (Focus), HP/poise (Vitality), companion/bind skills (Binding). Tune numbers with Game Designer; names are fixed.

**Stamina / Focus / Heat** (align Design Bible magic rules):

- Stamina: dodge, block, heavy/charged
- Focus: skills
- Heat: channeling / ultimates — overheat seals skills briefly (no AFK ultimate spam)

---

## 4. Telegraphs (mobile readability)

Every enemy attack that can punish the player must show **one clear tell** before hitboxes go live.

| Telegraph type | Visual | Color language (default) | Response |
|----------------|--------|--------------------------|----------|
| Dodge | Ground arc / dash line | Amber | Dodge |
| Block | Shield flash on weapon | Blue-white | Block |
| Unblockable | Red crack / skull pip | Red | Dodge or gap-close out |
| AoE | Expanding circle / cone | Amber → Red at commit | Leave zone |
| Projectile | Glow on caster + trail | School-tinted | Dodge / block per type |

**Rules:**

- Tell duration ≥ 0.45s on Mid (stretch slightly on Low if needed for readability).
- No multi-color spam: one dominant telegraph color per attack.
- Boss phase changes get a **phase banner** + audio sting + brief vulnerability or scripted beat.
- Soft particles off on Low; telegraphs must remain readable as mesh/decal, not particle-only.
- Haptics: light tick on tell start, heavier on hit (Battery Saver: optional off).

---

## 5. Poise / stagger

**Poise** = resistance to stagger. Light chips; Heavy/Charged/Skills break thresholds.

| Stagger state | Effect | Duration (tune) |
|---------------|--------|-----------------|
| None | Normal | — |
| Flinch | Brief interrupt, no full open | ~0.2–0.35s |
| Stagger | Attack cancelled; punish window | ~0.8–1.2s |
| Launch / knockdown | Rare; bosses mostly immune | Skill-defined |

**Player poise:** blocking builds stability; perfect block refunds some stamina and applies flinch to attacker. Guarding through Unblockable still takes full hit + heavy poise break.

**AFK:** Agent prefers breaking poise on elites before dumping ultimates; trash can be light-chained.

---

## 6. Enemy roles (≥3 for First Playable)

Distinct silhouettes + telegraph language per role. Field trash must not require PC-precision.  
**Emberveil flavors (CD-locked):** failed-binding ladder that climaxes in the Coil Warden.

| Role | Emberveil example | Behavior | Telegraph bias |
|------|-------------------|----------|----------------|
| **Skirmisher** | **Vein-mite** swarm | Flanks, short leaps, low poise | Dodge (amber leaps) |
| **Bruiser** | **Wake-warped stag** | Slow heavies, high poise, grabs | Block / Unblockable grab |
| **Caster** | **Conduit wisp** | Ranged orbs, AoE seals | Projectile + AoE circles |
| *(optional 4th)* **Support** | Amplify drone / mite nest | Buffs allies, fragile | Interrupt priority for agent |

**Density:** Open world packs mix 1 Bruiser + Skirmishers, or Caster behind front line. Never 3 Casters overlapping Unblockable AoEs in the slice.

---

## 7. Major boss (slice) — The Coil Warden

**CD lock:** `/workspace/ashcrown-docs/BOSS_COIL_WARDEN.md` · **Emberveil Reach** · dungeon **Coilcrypt**  
**Fantasy:** Wake-forged guardian fused to a buried battery coil, feeding on Aether bleed (failed binding apex).  
**Lean:** Wake-primary body/weapons/poise · Aether bleed as Phase 2 arena hazard · ash-light (ember/legacy) Phase 3 motif. One creature — not “magic half / gun half.”  
**Unique drop:** **Ash-etched Circlet Fragment** (tease toward Ashcrown; never full relic in First Playable).  
**Requirements:** 2–3 phases · readable tells · clearable on Manual; Full auto may stall/fail on late phases (fair AFK).

### Phases + telegraphs (feel sheet)

| Phase | HP band | Fantasy beat | Signature patterns | Telegraph focus | Player lesson |
|-------|---------|--------------|--------------------|-----------------|---------------|
| 1 | 100–60% | **Coil sentinel** — still on duty, testing | **Sweep Arc** (amber dodge coil arm), **Glyph Slam** (blue-white blockable), **Conduit Spit** (soft ranged) | Amber sweeps; blue-white slam; soft projectile | Dodge vs Block vocabulary |
| 2 | 60–30% | **Bleed surge** — coil cracks; vents open | **Aether Vent** (arena hazard primary, amber→red bloom), **Coil Overload** ×1–2 (red Unblockable — dodge out) | Mesh/decal vents + red rupture crack | Space control; Focus/heat pressure |
| 3 | 30–0% | **Crown echo** — ash-light on helm/circlet scar | Faster sentinel patterns; **enrage**; brief **poise windows** after overload stutter | Phase banner + sting; ash-light motif; punish on stagger | Commit skills/charged on poise break |

**Telegraph notes (boss-specific):**

- Silhouette first: metal guardian + coil spine readable at Mid before glow; Wake-metal frame stays through P3 (not particle soup).
- Vents = cool Aether on hazard only; ember accents on hits / phase transitions.
- Coil Overload is the teachable Unblockable for the slice; Assisted/Full auto must dodge (never “tank” it).
- Phase transitions: banner + sting + short vulnerability (~1s) before new pattern pool.
- Color language locked: amber dodge / blue-white block / red unblockable — no rainbow tells.

**Boss rules:**

- Unique loot: Ash-etched Circlet Fragment (first clear guaranteed for First Playable).
- No invisible hits; every lethal pattern telegraphed (mesh/decal, not particle-only).
- Companion can tank/peel Phase 1–2 Vein-mites but cannot solo the Warden on default profiles.
- Offline AFK: boss attempts only if profile = Boss and power ≥ gate; else skip and report.

---

## 8. Mobile touch layout (default)

- **Left:** virtual stick (move)
- **Right cluster:** Attack (large), Dodge, Block
- **Upper-right arc:** Skill 1–3, Ult (smaller, spaced for fat-finger)
- **Lock-on:** **soft-lock default ON** when a hostile is in range; tap silhouette or stick-flick to swap; dedicated unlock control
- Remappable; left-hand option mirrors clusters
- Min button hitbox ≥ 48–56 dp; attack ≥ 64 dp
- Combat HUD: HP / Focus / Heat / target name; damage numbers pooled and capped

Controller support = later; design verbs so they map cleanly.

---

## 9. Feel targets (tuning north stars)

| Beat | Target feel |
|------|-------------|
| Light chain | Snappy; commit ~0.25–0.4s per swing |
| Heavy | Windup readable; hit lands with weight + camera nudge |
| Dodge | Generous enough for Mid phone latency; not Dark Souls-tight |
| Parry | Narrower than dodge; Manual reward |
| Skill | Clear startup; AFK waits for safe windows |
| Hit confirm | Hitstop short (≤2–3 frames equiv) + haptic; never freeze AI long |

---

## 10. Godot implementation notes

- `CharacterBody3D` player/enemies; `Area3D` / shape casts for hitboxes
- AnimationTree for attack states; cancel windows authored in anim markers
- Telegraph decals + simple mesh cones (not particle-only)
- Object pool: projectiles, damage floats, telegraph instances
- Combat agent ticks on budget (throttle distant AI)
- Same `CombatAPI` for player controller and AFK agent

**Suggested resources:** `EnemyRole.tres`, `AttackTelegraph.tres`, `BossPhase.tres`, `CombatProfileRules.tres`

---

## 11. First Playable sign-off (Combat Designer)

- [ ] Manual: light/heavy/dodge/skill feel responsive on Mid preset
- [ ] Telegraphs readable on a phone-width viewport without particle crutch
- [ ] ≥3 enemy roles distinct in fight and silhouette
- [ ] Coil Warden: 2–3 phases, Ash-etched Circlet Fragment, clearable manually
- [ ] Assisted + Full auto use shared hooks; heal/retreat rules work
- [ ] No ultimate spam under heat rules in auto/AFK
- [ ] Touch layout documented + remappable stubs
- [ ] VFX/projectile pools within performance budget

---

## 12. Decisions log

| Decision | Status |
|----------|--------|
| Boss fantasy | **Locked (CD)** — The Coil Warden / Coilcrypt / Emberveil Reach; Wake-primary + Aether P2 vents + ash-light P3; drop Ash-etched Circlet Fragment |
| Soft-lock default | **Locked ON** for mobile combat |
| Assisted parry | **Locked OFF** for MVP (Manual-only); Full auto uses block/dodge |
| Attribute names | **Locked (GD)** — Might / Swift / Focus / Vitality / Binding |

---

*NEXT: author frame-data / `AttackTelegraph` + `EnemyRole` + `BossPhase` (Coil Warden) with Godot Engineer to this CD lock → sync utility weights with AFK AI Designer. Ping CD only if feel change forces a fantasy break.*
