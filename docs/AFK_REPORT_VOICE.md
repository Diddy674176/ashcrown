# Ashcrown — AFK Return Report Voice (First Playable)

**Owner:** Creative Director (copy/tone) · AFK AI Designer (schema) · Godot Engineer (UI bind)  
**Status:** LOCKED strings + tone for §82  
**Schema:** `AFK_AGENT.md` §7  
**Tone:** Field log from a trusted agent — plain, accurate, no joke spam (`TONE.md`)

---

## 1. Voice rules

- Second person to the Waker (“you”), or agent first person (“I held Ember Camp”) — pick **one** per build; **slice default: agent field log in first person**.
- Short sentences. Numbers first, flavor second.
- Never invent yields. Stop reasons must match enum truth.
- Rares get one calm highlight line — never ALL CAPS hype.
- Factions may color one optional bark if a memory flag fired; otherwise stay neutral Concord field tone.

---

## 2. Header templates

```
AFK complete — {profile} · {mode}
{duration_human} · Emberveil Reach
```

Examples:  
`AFK complete — Balanced · offline`  
`AFK complete — EXP · foreground`

---

## 3. Body lines (bind to schema)

| Field | Copy pattern |
|-------|----------------|
| kills | `Engagements closed: {kills}` |
| xp | `Ash-light gained: {xp} XP` (or `Experience: {xp}` if ash-light feels heavy in UI) |
| gold | `Ledger: +{gold} gold` |
| items | `Salvage: {item} ×{qty}` / rares: `Kept: {item} (rare)` |
| discoveries | `Marked: {poi_name}` |
| retreats | `Fell back {n}× — rules held` |
| deaths | `Stopped after fall — report sealed` |
| caps | `Cap applied: {cap_name}` |
| companion | `Rook: {summary}` |

**Slice minimum UI:** duration, profile, kills, xp, gold, stop_reason, 1–3 item lines. Rest can collapse under “Details.”

---

## 4. Stop reason strings (enum → player text)

| Enum / reason | Player string |
|---------------|---------------|
| player_cancel | `You called me back.` |
| death | `I fell. Report sealed.` |
| inventory_full | `Pack at limit — no vendor path.` |
| level_gap | `Threat above charter — held position.` |
| manual_quest | `Choice needed at {poi} — waiting on you.` |
| afk_blocked | `Coil Warden stays a waking fight.` |
| time_cap | `Session cap reached — fair rest.` |
| thermal | `Heat warning — switched to offline sim.` |
| retreat_unresolved | `Could not recover — stopped per rules.` |
| complete_ok | `Watch ended clean.` |

---

## 5. Sample report (Balanced · offline · 12 min)

```
AFK complete — Balanced · offline
12 minutes · Emberveil Reach

Engagements closed: 14
Ash-light gained: 820 XP
Ledger: +63 gold
Salvage: Vein-mite chitin ×8
Kept: Glowcap · uncommon ×2
Fell back 1× — rules held
Watch ended clean.
```

---

## 6. AFK Manager chrome (microcopy)

| UI | String |
|----|--------|
| Toggle on | `Agent watching` |
| Toggle off | `You have the watch` |
| Profile picker title | `Watch profile` |
| Rules button | `Hard rules` |
| Last report | `Last return` |
| Empty state | `No return yet — set a profile and rest the watch.` |

---

## 7. Forbidden

Meme jokes, fake hype (“INSANE HAUL”), loot-box language, lying about caps, cartoon emojis in report body.

---

*CD — ship these strings; AFK designer owns yield math; GE binds UI.*
