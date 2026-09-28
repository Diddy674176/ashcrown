# Ashcrown — Classless Starter (First Playable)

**Owner:** Game Designer (systems)  
**Engine:** Godot 4 mobile · **Scope:** §82 vertical slice  
**Status:** Locked for First Playable (attribute display names fixed here; CD may flavor copy only)

---

## 1. Principle

No permanent class. The player is a **Waker**. Power emerges from weapons, skills, armor weight, runes (stub), companion, and artifacts — not a locked archetype. Origin picks **region/faction lean**, not combat role.

---

## 2. Attributes (slice names — locked)

| Attr | Short | Primary effect |
|------|-------|----------------|
| **Might** | MIG | Heavy damage, poise break, carry soft cap |
| **Swift** | SWT | Light attack speed, dodge window, crit chance lite |
| **Focus** | FOC | Skill power, Focus pool, heat recovery |
| **Vitality** | VIT | Max HP, stagger resist |
| **Binding** | BND | Companion potency, summon/skill duration, Wake-craft lite |

**Point budget (slice):**  
- Level 1: base 8 / 8 / 8 / 8 / 6 (Binding slightly lower)  
- +2 attribute points per level (player chooses)  
- Respec: one free respec in town per §82; further costs gold (modest)

Creative Director may rename for lore flavor later; **systems keys stay MIG/SWT/FOC/VIT/BND**.

---

## 3. Starting loadouts (pick one at creation)

Creation chooses a **starter kit**, not a class. Kits teach verbs; all can respec into any hybrid later.

| Kit | Weapons | Skills | Armor | Play fantasy |
|-----|---------|--------|-------|--------------|
| **Ashblade** | One-hand blade + focus charm | Light slash skill · short dash strike | Medium | Frontline melee |
| **Veilbow** | Wake-etched bow + knife | Piercing shot · Nature DoT seed | Light | Kite / ranged |
| **Corebinder** | Staff · light Wake-pistol stub | Binding bolt · minor ward | Light/Med | Caster + pet prep |

All kits: potion ×5, focus tonic ×3, junk sell value enough for first repair.

---

## 4. Weapon mastery (stubs)

Three families in slice: **Blade**, **Bow**, **Wake-arm** (staff/arc).

| Rank | Unlock | Effect |
|------|--------|--------|
| 0 | Equipped | Base moves |
| 1 | ~20 kills with family | +Light damage |
| 2 | ~60 kills | Unlock charged variant / alt skill socket |
| 3 | Boss or dungeon clear with family | Small set-style passive |

Mastery is **accounted per family**, not kit — swapping weapons mid-slice is encouraged.

---

## 5. Skills & unlock cadence

- **Multi-school:** Elemental, Nature, Binding, Wake-craft (subset of DESIGN_BIBLE schools).  
- Unlock cadence: **one skill node every ~2 levels** (levels 2, 4, 6, 8) plus kit starters.  
- Max equipped combat skills in slice: **3 + ultimate** (matches COMBAT.md / COMBAT_LOOP.md).  
- Respec-friendly: nodes refundable at town smith/altar stub.  
- Heat rule: skills generate heat; overchannel seals school briefly — AFK must respect.

**Hybrid example (valid):** Veilbow + Nature DoT + Binding companion passive.

---

## 6. Armor weights

| Weight | Pros | Cons |
|--------|------|------|
| Light | Dodge window, Swift scaling | Low poise resist |
| Medium | Balanced | — |
| Heavy | Poise resist, Might synergy | Slower dodge, more stamina on dodge |

Slice: no full set bonuses beyond one **artifact** (boss exclusive) that defines a build hook.

---

## 7. Companion (one in slice)

- Recruit mid-slice via quest beat.  
- Role presets: **Guardian** (taunt/peel stub) or **Striker** (damage).  
- Scales with **Binding** + own gear stub.  
- AFK-capable: uses same combat hooks; player profile can prioritize companion safety.

---

## 8. Progression spine (numbers)

| Level | XP to next (approx) | Unlocks |
|-------|---------------------|---------|
| 1 | 100 | Kit skills |
| 2 | 180 | Skill node |
| 3 | 280 | — |
| 4 | 400 | Skill node · weapon mastery 1 likely |
| 5 | 550 | Companion recruit gate (quest) |
| 6 | 720 | Skill node · dungeon ready |
| 7 | 900 | Boss band |
| 8 | 1100 | Skill node · soft end of authored slice |
| 9–10 | steeper | Soft cap; AFK overnight capped |

**XP sources:** kills, quests, first discovery, dungeon rooms. AFK EXP profile uses same tables with anti-exploit caps (see AFK docs).

**Gear tiers:** Common → Uncommon → Rare → Epic (boss) → Legendary (boss exclusive, one). Compare/equip must show clear DPS/EHP delta.

---

## 9. Economy touchpoints (build-relevant)

- First meaningful **smith craft** before dungeon (tier-up weapon or armor).  
- Salvage → mats; vendors buy junk.  
- No P2W; no energy gates. Gold sinks: repair + craft + optional respec.

---

## 10. AFK interaction

Agent picks skills from **equipped loadout** + profile priorities. Never invents unequipped schools. Ultimate gated by heat/CD. Loot filter + inventory stop apply before greed-equip.

---

## 11. Godot data shape (hint)

Prefer Resources: `AttributeSheet`, `WeaponFamily`, `SkillNode`, `StarterKit`, `ArmorWeight`. Character save stores points spent + equipped node IDs — not a class enum.

---

## 12. Exit criteria

- [ ] Creation offers 3 kits; none locks class  
- [ ] Attributes spendable; one free town respec  
- [ ] Skill unlocks at 2/4/6/8 feel readable  
- [ ] Companion recruit changes combat without becoming a second player class  
- [ ] Boss artifact is the only build-defining spike in slice  

*Brand: Ashcrown only. Cross-ref: COMBAT_LOOP.md, SYSTEMS.md, FIRST_PLAYABLE.md, DESIGN_BIBLE.md*
