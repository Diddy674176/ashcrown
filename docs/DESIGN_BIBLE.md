# Ashcrown — Design Bible

**Working title (FINAL):** Ashcrown  
**Engine:** Godot 4 (mobile-first: Android + iOS)  
**Genre:** Fully AFK-capable open-world action RPG (fantasy / sci-fi hybrid)  
**Canonical repo:** https://github.com/Diddy674176/ashcrown  
**Status:** Design locked for First Playable vertical slice (brief §82)  
**Do not use:** Aetherwake, Ashen Crown (obsolete working titles)

---

## 1. Vision

Ashcrown is a premium open-world RPG that exists whether the player is watching or not. Active play feels like a AAA action RPG: responsive combat, exploration, companions, dungeons, and meaningful choices. AFK play is not a dumb auto-battle toggle — it is an intelligent autonomous agent that explores, fights, gathers, crafts, quests, and manages systems within player-defined priorities and rules.

**One-line pitch:** A living fantasy–sci-fi world your character can play for you — without becoming an idle clicker.

**Dual modes (equal first-class citizens):**
- **Active:** Manual control, skill expression, secrets, high-risk content.
- **AFK:** Profile-driven agent + offline simulation; detailed return reports.

---

## 2. Design Pillars

1. **World that remembers** — Player actions, wars, and settlements leave durable history NPCs and quests reference.
2. **Agent, not idle** — AFK uses goals, danger assessment, and stop conditions — never mindless farm loops only.
3. **Classless expression** — Builds emerge from weapons, skills, runes, and companions; no permanent class lock.
4. **Mobile-real AAA feel** — Touch-native controls, scalable graphics, thermal/battery budgets; never PC-ports-with-virtual-sticks.
5. **Vertical slice first** — One beautiful region done right before content sprawl.
6. **Fair AFK** — AFK progresses meaningfully; skilled active play retains advantages on bosses, secrets, and hard content.
7. **No predatory monetization** — Cosmetics/expansions OK; no P2W gear, energy gates, or AFK crippling for boosts.

---

## 3. Tone & Fantasy / Sci-Fi Hybrid

**Tone:** Mythic wonder with cold remnant tech. Hopeful exploration under a sky that still glows after an ancient catastrophe. Not grimdark; not goofy. Occasional melancholy ruins, bright living towns. The crown is ash and light — glory after fire.

**Hybrid lore spine — The Ashcrown:**
Long ago, the **Veil** between spirit and machine tore. **Aether** (living mana-light) flooded the world and fused with **Wake-tech** — the self-repairing engines of a fallen stellar civilization. Magic and machinery are one continuum. The **Ashcrown** is both a legendary relic (a Wake-forged circlet that survived the fire) and the name of the age of survivors who rebuild under its omen.

- **Aether** = animate energy that answers will, emotion, and ritual form.
- **Wake** = patterned remnant tech that stores, channels, and amplifies Aether.
- **Ashcrown** = the relic, the era, and the player's path as a **Waker** who can bind both.

**Regions feel dual:** forests with crystalline conduits; castles built over orbital battery cores; deserts of sandglass and heat-sink ruins; floating isles held by gravity anchors.

**Art language (high level):** Saturated dusk skies, bioluminescent aether veins, brushed-metal Wake glyphs beside carved runes, ash-gold and ember accents, readable silhouettes, UI that mixes manuscript ornament with clean HUD geometry.

---

## 4. Lore Spine (playable)

### Creation myth (player-facing short)
The First Choir sang matter into shape. The Builders answered with machines that remembered songs. Pride broke the Veil; the world burned and remade. Nations now quarrel over **Cores** — Wake hearts still pulsing under cities — and over who may wear or claim the Ashcrown's legacy.

### Current age
- Fractured kingdoms and free cities compete for Core access.
- **Choirbound** faiths treat Aether as sacred; **Wakewrights** treat it as engineering; **Gray Concord** brokers uneasy peace.
- Monsters are often **Wake-warped** wildlife or failed bindings, not generic fantasy fodder.

### Player role
A newly woken Waker. Origin chooses starting region/faction lean, not combat class. Story mystery: who (or what) stirred a second Wake — and why the player survived with ash-light in their blood.

---

## 5. Magic Rules (coherence contract)

| Rule | Detail |
|------|--------|
| **Source** | Aether drawn from environment, personal reserve, or Wake conduits |
| **Cost** | Stamina/Focus + heat (overchannel risks burnout / temporary seal) |
| **Limitation** | No free resurrection spam; no infinite teleport; space/time schools are rare and expensive |
| **Schools** | Elemental, Light, Shadow, Nature, Binding (summon), Alchemy, Wake-craft (tech-magic), Illusion |
| **Forbidden** | Unbound Necromancy (steals memory from living), Core rupture, Veil tearing rituals |
| **Hybrid** | Weapons can be Wake-etched; spells can require catalysts; guns exist only as Wake-arc throwers where lore-appropriate |

Combat VFX and AFK skill use must obey these costs so auto-play cannot dump ultimates forever.

---

## 6. AFK Philosophy

AFK is a **player-authored agent**:

- Profiles (EXP, Gold, Gathering, Boss farm, Dungeon, Quest, Explore, Craft, Reputation, Gear, Companion, Kingdom, Balanced, Custom).
- Hard rules (level gap, HP retreat, loot filters, spend caps, never auto-consume premium/rare).
- **Foreground AFK:** full agent on device with reduced graphics / capped FPS.
- **Offline AFK:** deterministic-ish simulation from last profile + power + resources; anti-exploit caps; rich report on return.
- Optional future **cloud AFK** is non-blocking for solo design.

AFK must understand danger, quest weight, inventory pressure, and stop conditions. Active skilled play still wins on mythic bosses, puzzle dungeons, and secrets.

---

## 7. Quality Bar Questions

For every system: Fun? Understandable? Connected? Mobile-viable? Scalable? AFK-aware? Worth its cost? If no — cut or simplify.

---

## 8. Out of scope for First Playable

Kingdom wars, raids, seasons, full multiplayer, sailing fleets, full housing trees, New Game+, mythic endgame. Documented in ROADMAP; not blockers for §82 slice.

---

*Engine lock: Godot 4. Docs under `/workspace/ashcrown-docs/`. NEXT after studio bots + repo docs: Godot 4 project scaffold.*
