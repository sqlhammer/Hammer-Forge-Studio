# M3 HUD Layout Overview

**Ticket:** TICKET-0019
**Last Updated:** 2026-02-22

> Master layout showing the spatial relationship of all M3 HUD elements on a 1920x1080 screen. Programmers should reference individual wireframe documents for component details.

---

## Full-Screen HUD Map

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  32px safe margin                                                            │
│  ┌──────────────────────────────────────────────────────────────────────────┐│
│  │                                                                          ││
│  │                    ┌─────────────────────────┐                           ││
│  │                    │       COMPASS BAR        │ ◄── top-center           ││
│  │                    │  W  NW  N  NE  E  ▼47m  │     32px from top        ││
│  │                    └─────────────────────────┘     600x32px              ││
│  │                                                                          ││
│  │                                                                          ││
│  │                                                                          ││
│  │                                                                          ││
│  │                                                                          ││
│  │                              +  ← crosshair (center)                     ││
│  │                                                                          ││
│  │                         EXTRACTING                                       ││
│  │                    ┌──────────────────┐     ┌──────────────────────┐      ││
│  │                    │█████████░░░░░░░░░│     │  ◆ SCAN RESULTS     │      ││
│  │                    └──────────────────┘     │  Purity   ★★★★☆     │      ││
│  │                    ↑ mining progress         │  Density  Medium    │      ││
│  │                      center, +60px below     │  Energy   34% ⚡    │      ││
│  │                      crosshair               └──────────────────────┘    ││
│  │                      240x12px                ↑ scanner readout            ││
│  │                                                center-right               ││
│  │                                                260x160px                  ││
│  │                                                                          ││
│  │                                                                          ││
│  │                                          ┌──────────────────────┐        ││
│  │                                          │ [i] Scrap Metal  x5  │        ││
│  │                                          └──────────────────────┘        ││
│  │                                          ┌──────────────────────┐        ││
│  │                                          │ [i] Scrap Metal  x3  │        ││
│  │                                          └──────────────────────┘        ││
│  │                                          ↑ pickup notifications           ││
│  │  ┌──────────────────────────┐              center-right                  ││
│  │  │ ⚡ ████████░░░░  72%     │              260x48px each                 ││
│  │  └──────────────────────────┘                                            ││
│  │  ↑ battery bar                                                           ││
│  │    bottom-left, 32px margins                                             ││
│  │    200x48px                                                              ││
│  └──────────────────────────────────────────────────────────────────────────┘│
│  32px safe margin                                                            │
└──────────────────────────────────────────────────────────────────────────────┘
                              1920 x 1080
```

---

## Element Z-Order (CanvasLayer)

| Layer | Elements |
|-------|----------|
| **Layer 0** | 3D game world |
| **Layer 1** | All HUD elements (compass, battery, mining progress, scanner readout, pickup notifications) |
| **Layer 2** | Overlay screens (inventory — full screen with dim background) |

HUD elements on Layer 1 are always visible during gameplay. When the inventory overlay (Layer 2) opens, HUD elements remain visible behind the dim but are non-interactive.

---

## Conflict Zones

These element pairs can appear simultaneously — verify they don't overlap:

| Element A | Element B | Conflict? | Resolution |
|-----------|-----------|-----------|------------|
| Mining progress (center) | Scanner readout (center-right) | No — scanner readout dismisses when mining starts |
| Pickup notifications (right) | Scanner readout (right) | Possible — pickup toasts are vertically centered, readout is center-right with -40px offset. Gap is sufficient at 1080p. If both appear, toasts stack below the readout |
| Battery bar (bottom-left) | Mining progress (center) | No — different regions |
| Compass (top-center) | Everything else | No — top region is exclusive to compass |

---

## Wireframe Index

| Component | File | Screen Position |
|-----------|------|-----------------|
| Compass Bar | [`compass.md`](compass.md) | Top-center |
| Battery Bar | [`battery-bar.md`](battery-bar.md) | Bottom-left |
| Scanner Readout | [`scanner-readout.md`](scanner-readout.md) | Center-right |
| Mining Progress | [`mining-progress.md`](mining-progress.md) | Center (below crosshair) |
| Pickup Notification | [`pickup-notification.md`](pickup-notification.md) | Center-right (stacking) |
| Inventory Screen | [`inventory.md`](inventory.md) | Full-screen overlay (centered) |
