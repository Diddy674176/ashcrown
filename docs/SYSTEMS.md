# Ashcrown — Systems (Godot 4 mobile scope)

Scoped for implementability on Godot 4 mobile. Prefer data-driven resources (`.tres` / custom Resources) and signal buses over hard coupling.

---

## 1. Combat

**Modes:** Manual · Assisted · Full auto (same decision hooks as AFK combat agent).

**Core verbs:** Light / Heavy / Charged · Dodge · Block · Perfect block/parry · Skills · Ultimate · Lock-on + free aim · Weapon swap.

**Resolution:** Hitboxes + telegraphs; stagger/poise; status effects; elemental combos (respect magic heat rules).

**Mobile:** Touch layouts remappable; left-hand option; controller support later; haptics on impact.

**Godot notes:** `CharacterBody3D`, AnimationTree, limited simultaneous VFX; object pool projectiles; animation LOD.

**Bosses (slice):** One major boss — 2–3 phases, readable tells, unique drop. Field trash must not require PC-precision.

---

## 2. Classless builds

No permanent class. Power from:

- Attributes (Might / Swift / Focus / Vitality / Binding — locked in CLASSLESS_STARTER.md; CD may flavor copy only)
- Weapon mastery trees
- Armor weights (light/medium/heavy tradeoffs)
- Skill nodes (multi-school, respec-friendly)
- Runes / enchantments / set bonuses
- Companion passives
- Artifacts (build-defining, not raw stat sticks)

**Hybrid encouragement:** e.g. Wake-etched bow + Nature DoTs + Binding pet — valid if costs obeyed.

**AFK:** Agent picks skills from equipped loadout + profile priorities; never infinite ultimate spam (heat/cooldown).

---

## 3. AFK profiles & agent

**Architecture (lite for slice):**
- **Perception:** HP/Focus, nearby threats, loot value, quest targets, nav links, inventory fill %
- **Decision:** Utility scores from active profile + player rules
- **Execution:** Move, fight, loot, heal, retreat, vendor sell/salvage stubs, craft queue tick

**Built-in profiles:** EXP · Gold · Gathering · Boss · Dungeon · Quest · Explore · Craft · Reputation · Gear · Companion · Kingdom · Balanced · Custom

**Rules examples:** max level gap · retreat HP% · potion HP% · inventory stop · loot keep/salvage/sell · gold spend caps · never auto premium

**Reports:** time, distance, kills, bosses, XP/levels, gold, items, rares, quests, discoveries, craft, companion, deaths/retreats, events

**Offline:** Store profile + state → simulate with caps from power/resources → report. No impossible farms.

**Godot notes:** Run agent on idle frame budget; when app backgrounded, prefer offline sim path over full 3D loop to save battery.

---

## 4. Living world (slice-scoped)

**In First Playable:**
- One region with town + wilderness + dungeon
- NPC schedules (day/night) for key NPCs
- One faction rivalry affecting prices/quests
- Memory flags: saved village / helped NPC / ignored threat
- Weather + day/night affecting spawns/visibility lightly

**Simulation LOD (design now, implement gradually):**
- L0 full near player
- L1 simplified nearby
- L2 abstract regional
- L3 statistical offline

**Out for slice:** Full kingdom wars, continent-scale economy, thousands of NPCs at L0.

---

## 5. Adjacent systems (slice minimum)

| System | Slice bar |
|--------|-----------|
| Quests | Authored chain + 1–2 dynamic bounties |
| Loot | Common→Legendary tiers; boss exclusive |
| Crafting | Smith + alchemy stubs + AFK queue |
| Companion | One recruitable with role preset + auto combat |
| Economy | Vendors + salvage; regional price modifiers lite |
| UI | Character, Inventory, Map, Quests, Skills, AFK Manager, Settings |

---

## 6. Module map (Godot)

Suggested `res://` modules: `Core/`, `Character/`, `Combat/`, `AI/`, `AFK/`, `World/`, `Streaming/`, `Quests/`, `NPC/`, `Factions/`, `Inventory/`, `Items/`, `Loot/`, `Crafting/`, `Companions/`, `Dungeons/`, `Save/`, `UI/`, `Audio/`

Use interfaces/events; keep AFK able to call the same combat/quest APIs as the player.

---

*See PERFORMANCE_BUDGET.md for mobile constraints that override feature greed.*

*First Playable detail: COMBAT_LOOP.md · CLASSLESS_STARTER.md*
