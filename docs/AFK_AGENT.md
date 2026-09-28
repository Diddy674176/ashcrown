# Ashcrown — AFK Agent Architecture (Godot 4 Mobile)

**Owner:** AFK AI Designer  
**Brand:** Ashcrown  
**Status:** MVP profiles + offline rules locked for grind — First Playable (§82) ready to implement  
**Depends on:** DESIGN_BIBLE §6, SYSTEMS §3, FIRST_PLAYABLE, PERFORMANCE_BUDGET AFK section  
**Repo target:** `docs/AFK_AGENT.md` in https://github.com/Diddy674176/ashcrown

---

## 1. North star

AFK is a **player-authored autonomous agent**, not an idle clicker.

- Same combat / quest / inventory APIs as the human player.
- Goals, danger assessment, inventory pressure, and **stop conditions**.
- Skilled active play still wins mythic bosses, puzzle dungeons, and secrets.
- Battery-aware: prefer offline sim when suspended; never burn battery on full 3D in background.
- Fair: meaningful AFK progress with **anti-exploit caps**; no impossible farms.

---

## 2. Runtime modes

| Mode | When | What runs | Graphics / FPS |
|------|------|-----------|----------------|
| **Foreground AFK** | App focused, AFK on | Full agent loop on device | Force Battery Saver or Mid-Low; FPS ≤ 30; VFX/shadows cut |
| **Offline AFK** | App suspended / killed / player closed | Deterministic-ish sim from last profile + power + resources | No 3D; battery-safe |
| **Cloud AFK** | Future optional | Out of First Playable | — |

**Rule:** On OS background / thermal warning, hand off to offline sim path. Do not keep a 3D agent running if the OS backgrounds the app.

---

## 3. Pipeline (every tick / sim step)

```
Perception → Utility Decision → Action Selection → Execution → Report Accumulator
```

### 3.1 Perception (inputs)

All as cheap blackboards / signals — no expensive queries every frame.

| Signal | Notes |
|--------|--------|
| HP%, Focus/stamina%, heat | Retreat / heal / skill gating |
| Nearby threats (count, max level gap, telegraph flags) | Danger score |
| Quest targets in range / on path | Quest weight |
| Loot value nearby + inventory fill % | Loot / stop |
| Nav links (town, vendor, camp, dungeon entrance) | Travel goals |
| Profile + hard rules | Decision weights |
| Companion state | Assist / protect |
| Time-of-day / weather lite | Spawn / visibility bias (slice: light touch) |

**Tick budget:** Throttle AI when far from player-relevant action; share idle frame budget with other systems (PERFORMANCE_BUDGET: CPU ≤ 8 ms headroom @ 30 FPS).

### 3.2 Decision (utility)

Each candidate action `a` gets:

\[
U(a) = \sum_i w_i \cdot s_i(a) - \sum_j p_j(a)
\]

- \(w_i\): weights from **active profile** (+ custom overrides)
- \(s_i\): normalized scores in \([0,1]\) (e.g. EXP gain estimate, gold/hour, quest progress, danger inverse, inventory headroom)
- \(p_j\): penalties (level-gap danger, rule violations, premium spend, overheat)

Pick argmax among **legal** actions (rules filter first). Soft ties → prefer safer / closer.

**Never:** dump ultimates forever (heat + cooldown gates), ignore retreat HP%, auto-consume premium/rare.

### 3.3 Execution verbs (slice)

Move · Engage · Disengage/Retreat · Heal/Potion (per rules) · Loot · Interact (quest NPC / vendor stub) · Craft queue tick · Stop AFK (emit report)

Combat uses the **same** Assisted / Full-auto decision hooks as manual auto-combat (SYSTEMS §1).

---

## 4. First Playable / MVP profile set

**Locked MVP (The Man / Bob grind direction):** **EXP · Gold · Explore · Balanced** (+ Custom rules overlay).

Ship these four built-ins for §82. Remaining bible profiles stay data-defined stubs for later.

| Profile | Primary weights | Typical loop | Offline bias |
|---------|-----------------|--------------|--------------|
| **EXP** | Combat XP, clear camps, avoid deadly gap | Wilderness camps → retreat → vendor if full | Prefer denser trash packs; skip low-XP travel |
| **Gold** | Vendor value, salvage, efficient kills | Trash with good sell rates → vendor → resume | Prefer gold/hr nodes; skip vanity rares that clog bag |
| **Explore** | Fog clear, POIs, discovery flags, light combat | Path to unexplored nav links → skim fights → mark finds | Favor unvisited chunks; lower kill density OK |
| **Balanced** | Mix XP + gold + explore crumbs + bag health | Rotate camps / vendors / fog edges | Blend rates; never starve one axis to zero |
| **Custom** | Player sliders over the same score axes | Player-authored | Same sim, player weights |

**Deferred (stubs only):** Gathering, Boss, Dungeon, Quest, Craft, Reputation, Gear, Companion, Kingdom.

### Hard rules (always on, Custom can tighten not loosen safety floors)

| Rule | Default (slice) | Notes |
|------|-----------------|-------|
| Max enemy level gap | +3 | Stop or skip target if above |
| Retreat HP% | 35% | Disengage → heal → re-eval |
| Potion HP% | 50% | Only if potions allowed & stocked |
| Inventory stop | 90% full | Vendor sell/salvage stub or stop |
| Loot filter | Keep ≥ Rare; salvage/sell junk per toggle | Never auto-destroy unique/quest |
| Gold spend cap | 0 in AFK unless Custom allows | No impulse buys |
| Premium / rare consumables | **Never** auto | Explicit player opt-in later |
| Session / offline time cap | See §6 | Anti-exploit |

---

## 5. Stop conditions

AFK **must** stop (or hand to offline report) when any fire:

1. Player cancels  
2. Retreat failed / death (count death; optional revive policy: stop on death for slice)  
3. Inventory stop + no vendor path  
4. Level-gap / danger ceiling exceeded for current goal  
5. Quest step requires **manual** interaction (puzzle, dialogue choice, mythic gate)  
6. Boss / content flagged `afk_blocked`  
7. Time / yield caps (§6)  
8. Battery Saver thermal critical (drop to offline sim or stop)  
9. Rule violation that cannot be resolved (e.g. out of potions and HP below retreat)

On stop: freeze agent, write **Return Report**, show AFK Manager summary.

---

## 6. Offline simulation & fairness

### Inputs snapshot (saved on suspend / AFK start)

Profile id + custom weights · power rating (level, gear score lite) · region / safe zone · resources (potions, bag space) · explore fog mask / discovery flags · quest flags · companion · RNG seed · wall-clock start

### Offline decision rules (MVP)

Sim does **not** replay 3D combat. Each wall-clock minute (or batch of minutes) the offline brain:

1. **Eligibility** — If stop conditions already met in snapshot (bag full with no vendor path, dead, `afk_blocked` content only), emit report with zero further yield.
2. **Goal pick** — From active profile weights, pick one abstract goal for the slice: `farm_pack` | `vendor_trip` | `explore_chunk` | `heal_recover` | `idle_safe`.
   - EXP → heavy `farm_pack`
   - Gold → `farm_pack` biased to sell-value tables, then `vendor_trip` when bag ≥ 70%
   - Explore → `explore_chunk` until fog budget spent, with light `farm_pack` if blocked by trash
   - Balanced → weighted rotate; force `vendor_trip` before bag hard-stop
3. **Resolve goal** — Pull yield from region difficulty × power curves (XP, gold, junk/rare rolls, fog cells cleared). Apply retreat/death chance from danger vs power.
4. **Rules filter** — Same hard rules as foreground (level gap, never premium, gold spend cap). Illegal outcomes are discarded and re-rolled once, then skipped.
5. **Caps** — Apply table below, record `caps_hit`.
6. **Accumulate** — Append to report; advance simulated inventory/fog/HP state for next minute.

**Profile-specific offline multipliers (starting points — tune in playtest):**

| | XP/hr curve | Gold/hr curve | Fog cells/hr | Combat risk |
|--|-------------|---------------|--------------|-------------|
| EXP | 1.0 | 0.5 | 0.2 | Medium |
| Gold | 0.55 | 1.0 | 0.15 | Medium |
| Explore | 0.4 | 0.35 | 1.0 | Low–Med |
| Balanced | 0.7 | 0.7 | 0.45 | Medium |

### Caps (anti-exploit)

| Cap | Intent |
|-----|--------|
| Soft diminishing returns after 120 min wall-clock | Discourage 8h abuse without punishing short AFK |
| Hard wall: XP / gold / mats per real hour | Anti-exploit |
| Explore fog: max cells/hr + unique POI rate | No map-wipe overnight |
| Death/retreat chance scales with danger vs power | Truthful risk |
| No drops from `afk_blocked` bosses | Active skill retained |
| No premium currency / pay-gated mats | Fair economy |
| Inventory capacity still binds | Can't print infinite loot |

**Truthfulness bar:** 10 minutes foreground AFK vs 10 minutes offline for the same profile → **comparable** outcomes (documented variance band, e.g. ±15–25%). Offline must never beat an attentive active farm of the same content by a large factor.

### Determinism

Same seed + snapshot → same report. Seed stored in save for support / replay.

---

## 7. Return report (schema)

UI: AFK Manager → last session card. Persist on save.

```text
duration_sec
distance_approx          # foreground only; offline may omit or estimate
kills
bosses_attempted / cleared
xp_gained / levels_gained
gold_gained / gold_spent
items_looted[]           # id, rarity, qty — rares highlighted
quests_advanced[]
discoveries[]            # slice: light
craft_ticks_completed
companion_summary
deaths / retreats
stop_reason              # enum from §5
mode                     # foreground | offline
caps_hit[]               # which anti-exploit caps applied
events[]                 # notable: near-death, rare drop, quest complete
```

Copy tone: plain, trustworthy, no fake hype. Rares and stop reasons must be accurate.

---

## 8. Godot module sketch

`res://AFK/` (and shared hooks in `AI/`, `Combat/`, `Save/`, `UI/`)

| Resource / node | Role |
|-----------------|------|
| `AfkProfile` (Resource) | Weights, display name, icon |
| `AfkRules` (Resource) | Hard rules + Custom overrides |
| `AfkBlackboard` | Perception snapshot |
| `AfkUtilityBrain` | Score + pick action |
| `AfkExecutor` | Calls Character / Combat / Inventory APIs |
| `AfkOfflineSim` | Caps + L3 yields → report |
| `AfkReport` (Resource) | Serializable report |
| `AfkManager` (UI) | Profile pick, rules, start/stop, report |

**Signals:** `afk_started`, `afk_stopped(report)`, `afk_rule_blocked(reason)`.

Agent must call the **same** APIs as the player for combat, loot, quest advance — no parallel cheat path.

---

## 9. First Playable acceptance (AFK AI Designer sign-off)

From FIRST_PLAYABLE.md — this role signs when:

- [ ] EXP · Gold · Explore · Balanced + Custom rules work in foreground AFK  
- [ ] Auto combat uses telegraphs + heal/retreat rules (not mash)  
- [ ] Offline progression produces a **truthful** return report after close/reopen  
- [ ] Stop conditions fire correctly (inventory, danger, death, manual gate)  
- [ ] Caps documented and visible when hit (`caps_hit` in report)  
- [ ] Battery path: background → offline sim (no silent 3D drain)  
- [ ] Mid-range device / emulator: AFK intro in first-session flow without critical blockers  

---

## 10. Decisions

| Topic | Status |
|-------|--------|
| MVP profiles | **Locked:** EXP · Gold · Explore · Balanced (+ Custom) |
| Offline decision rules | **Locked draft** in §6 (goal pick → resolve → rules → caps) |
| Death policy | Default **stop AFK on death** for slice (pending Bob override) |
| Soft / hard time caps | Soft DR @ 120 min; hard walls per-hour — tune numbers in playtest |
| Commit to repo | **Done** — `docs/AFK_AGENT.md` on `main` |

---

*NEXT: Godot `AFK/` Resource stubs with Godot Engineer; auto-combat telegraph parity with Combat Designer; report UI with studio channel.*
