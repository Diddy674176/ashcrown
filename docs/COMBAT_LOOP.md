# Ashcrown — Combat Loop (First Playable)

**Owner:** Game Designer (systems) · **Feel owner:** Combat Designer  
**Engine:** Godot 4 mobile · **Scope:** §82 vertical slice only  
**Status:** Locked for First Playable implementation (refine feel with Combat Designer)

**Detail feel / telegraphs / boss phases:** [COMBAT.md](COMBAT.md) (Combat Designer). This doc owns the **systems loop**, mode parity, and progression gates.

---

## 1. Why this loop exists

Active combat must feel like a responsive action RPG on a phone. Assisted and Full Auto must use the **same verbs, costs, and danger rules** as the AFK combat agent — never a dumb mash mode. Manual play keeps the edge on bosses and hard tells.

---

## 2. Core verbs (all modes)

| Verb | Input (default) | Cost | Notes |
|------|-----------------|------|-------|
| Light attack | Primary attack | Stamina small | Chains 2–3 hits; cancels into dodge on most frames |
| Heavy attack | Hold / secondary | Stamina medium | Higher stagger; telegraphed windup |
| Charged | Hold past heavy threshold | Stamina + Focus small | Interruptible; punishable |
| Dodge | Dodge button | Stamina | i-frames short; directional |
| Block | Hold block | Stamina on hit | Perfect block window → parry (slice: one weapon family) |
| Skill | Skill slots 1–3 | Focus / heat | School-tagged; respects magic heat rules (see COMBAT.md) |
| Ultimate | Ult button | Full Focus + heat spike | Hard cooldown; **AFK/auto never spam** (heat + CD gate) |
| Weapon swap | Swap | None / tiny stamina | Two weapons max in slice |
| Lock-on | Toggle / soft lock | — | Soft lock default on mobile; free aim optional |

**Non-verbs for slice:** Jump-cancel combos, full move lists, dual-wield complexity beyond swap.

---

## 3. Session combat loop (player-facing)

1. **Engage** — Soft lock or approach; telegraphs readable at Mid graphics.  
2. **Trade** — Light/heavy weave; dodge or block vs tells.  
3. **Spend** — Skills when Focus allows; watch heat (overchannel = temporary seal).  
4. **Recover** — Potion under HP rule, or retreat to reset.  
5. **Resolve** — Kill → loot roll → brief power check (equip if upgrade).  
6. **Push or leave** — Continue pack / camp / dungeon room, or open AFK Manager.

Same six steps drive Assisted and Full Auto; only the decision source changes (player vs utility scores).

---

## 4. Modes

| Mode | Who decides verbs | Use |
|------|-------------------|-----|
| **Manual** | Player | Default; secrets, bosses, hard content |
| **Assisted** | Player aims/moves; auto skill/heal under rules | Fatigue / learning |
| **Full Auto** | Same hooks as AFK combat agent | Short AFK-in-combat; foreground farm |

Assisted and Full Auto **must** honor: retreat HP%, potion HP%, max level gap, heat/CD on ultimates, no auto-consume premium/rare.

---

## 5. Resolution (slice)

- Hitboxes + clearly telegraphed enemy attacks (color + windup pose).  
- **Poise/stagger:** light builds stagger; heavy/charged and some skills break poise. Boss phases gate on poise or scripted HP thresholds (Combat Designer owns timings).  
- **Status:** Burn / Chill / Bind (Wake-seal) — at most 2 stacking meaningful statuses for slice readability.  
- **Elemental combo:** optional light bonus if weapon school + skill school match; not required for clear.  
- Trash fights: clearable without perfect-parry mastery. Boss: 2–3 phases, unique drop.

---

## 6. Enemy roles (≥3 types)

| Role | Job | AFK note |
|------|-----|----------|
| **Grunt** | Pressure, low HP | Agent prioritizes closest threat |
| **Ranged poke** | Force dodge / close gap | Agent closes or uses cover stub |
| **Elite / mini** | Poise checks, one hard tell | Retreat rule may fire |
| **Boss** (1) | Phases, unique loot | Manual preferred; auto allowed but inefficient |

---

## 7. Power curve (combat-facing)

Aligned with systems progression spine (levels 1→8, soft cap 10):

| Band | Levels | Combat expectation |
|------|--------|--------------------|
| Tutorial | 1–2 | One weapon family; light/dodge/skill1 |
| Field | 3–5 | Heavy + skill2; first gear upgrade matters |
| Dungeon | 5–7 | Companion in fight; heat management matters |
| Boss | 6–7 target | Mid-tier weapon; underleveled AFK alone should struggle |

Gear > skill unlocks > companion passive for slice DPS. Attributes matter but stay secondary to weapon tier.

---

## 8. Godot hooks (for Engineer)

- Shared `CombatAction` / ability Resources used by player, Assisted, Full Auto, and AFK agent.  
- `CharacterBody3D` + AnimationTree; pooled projectiles; VFX budget from PERFORMANCE_BUDGET.  
- Telegraph decals/meshes toggle with quality preset.  
- Signal bus: `damage_dealt`, `poise_broken`, `player_downed`, `combat_ended` for loot/quest/AFK.

---

## 9. Hand-offs

| Role | Owns |
|------|------|
| Game Designer | This loop, costs, mode parity, power gates |
| Combat Designer | Frame data feel, telegraph readability, boss phases |
| AFK AI Designer | Utility scores calling the same verbs |
| Godot Engineer | Input map, hit detection, pooling |

---

## 10. Exit criteria (combat portion of §82)

- [ ] Manual light/heavy/dodge/skill feel responsive on mid-range touch  
- [ ] Full Auto uses telegraphs + heal/retreat rules (not mash)  
- [ ] Boss clearable; unique drop grants readable power bump  
- [ ] AFK/auto cannot infinite-ultimate (heat + CD verified)

*Brand: Ashcrown only. Cross-ref: SYSTEMS.md, CLASSLESS_STARTER.md, FIRST_PLAYABLE.md, PERFORMANCE_BUDGET.md*
