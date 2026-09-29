# Ashcrown — Mobile Controls (default layout)

**Version:** 0.2.1  
**Persist:** `SaveManager.control_layout` + `control_stick_side`

## Default layout (`default`, stick side `left`)

| Control | Screen side | Notes |
|---------|-------------|--------|
| Move stick | **Bottom-LEFT** | Deadzone 0.15 |
| Look / pinch-zoom | Full-screen LookZone | Right-thumb swipe; 2-finger pinch |
| Attack / Dodge / Block / Skills / Jump / USE | **Bottom-RIGHT** cluster | Hold ATK = heavy |
| Agent / Profile / Mode / Lock / Gfx / **Controls** | Top-RIGHT | Controls opens remap panel |

## Left-hand layout (`left_hand`, stick side `right`)

Mirrors the default: stick bottom-RIGHT, button cluster bottom-LEFT. Use **Controls → Left-hand layout** or **Swap stick side**.

## Hidden / unfinished

- Per-button free drag remap — hidden until authored (P2+)
- Custom opacity / size sliders — not exposed yet

## Reset

**Controls → Reset defaults** restores stick LEFT + cluster RIGHT and writes save.
