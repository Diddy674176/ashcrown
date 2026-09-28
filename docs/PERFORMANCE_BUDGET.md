# Ashcrown — Performance Budget (Godot 4 Mobile)

Mobile performance is mandatory. Features that break this budget get LOD'd or cut.

---

## Device tiers

| Tier | Examples (indicative) | Target FPS | Resolution policy |
|------|----------------------|------------|-------------------|
| Low | 3–4yr mid Android | 30 locked | Dynamic scale 0.6–0.8 |
| Mid | Current mid-range | 30/45 | 0.8–1.0 |
| High | Flagship | 60 | 1.0; optional 90/120 later |

Presets: **Battery Saver · Low · Medium · High · Ultra**

---

## Frame budgets (aim)

- **CPU game logic:** ≤ 8 ms @ 30 FPS headroom; AI tick throttle when far
- **GPU:** Prefer forward+/mobile-friendly; limit real-time lights (e.g. 1 dir + few omni)
- **Draw calls:** Soft cap ~80–150 on mid (profile per device); GPU instancing for foliage/debris
- **Triangles on screen:** Soft ~150k–300k mid with LODs; aggressive mesh LOD
- **Particles:** Cap active systems; disable soft particles on Low
- **Shadows:** Cascades reduced/off on Low; single cascade Mid
- **Memory:** Keep working set comfortable for 3–4 GB devices; texture streaming; compress (ETC2/ASTC)
- **Audio:** Voice/important SFX prioritized; music stems limited

---

## World streaming

- Chunked/region streaming (Godot `GridMap` / custom chunk loader / `WorldBoundary`)
- HLOD / impostors for distant town silhouettes
- Occlusion + frustum culling
- Animation LOD (reduce bones/update rate by distance)
- NPC sim LOD (see SYSTEMS.md)

---

## AFK / battery / thermal

- AFK foreground: force Battery Saver or Mid-Low; FPS cap 30; reduce shadows/VFX
- Prefer **offline simulation** when app suspended — do not burn battery on full 3D AFK if OS backgrounds the app
- Respond to thermal warnings: drop resolution, shadows, FPS
- Background AFK must not "destroy battery"

---

## Godot-specific checklist

- [ ] Use mobile renderer (Forward Mobile) as default export
- [ ] Object pooling (projectiles, damage numbers, pickups)
- [ ] Avoid per-frame GDScript alloc storms; profile with Godot debugger
- [ ] Bake GI lightly or use probes; no expensive desktop GI on mobile path
- [ ] Atlas UI textures; control Control node count in HUD
- [ ] Physics: limit active rigid bodies; prefer CharacterBody + Area
- [ ] Shader variants: few custom shaders; precision mediump where safe

---

## Profiling cadence

Before each phase exit: frame time, draw calls, tris, memory, GC/jank, AI cost, physics, streaming spikes. Fix bottlenecks before adding systems.

---

## Non-negotiables

1. Stable target FPS on Mid preset on a defined reference device list
2. No feature ships without CPU/GPU/memory/battery note
3. Scalable quality — never "delete the game on Low"; degrade gracefully
