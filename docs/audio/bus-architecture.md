# Audio Bus Architecture

**Owner:** audio-engineer
**Status:** Draft
**Last Updated:** —

> Describes all Godot AudioServer buses, their effects chains, and routing. Update this document whenever a bus is added or modified.

---

## Bus Hierarchy

```
Master
├── Music
├── SFX
│   ├── SFX_Player
│   └── SFX_Enemy
├── Ambient
├── UI
└── Voice
```

---

## Bus Definitions

| Bus Name | Sends To | Effects | Purpose |
|----------|----------|---------|---------|
| Master | (output) | Limiter | Final output |
| Music | Master | Compressor | All music tracks and layers |
| SFX | Master | — | General sound effects |
| SFX_Player | SFX | — | Player-specific SFX (footsteps, abilities) |
| SFX_Enemy | SFX | — | Enemy-specific SFX |
| Ambient | Master | Reverb | Environmental ambient loops |
| UI | Master | — | Menu and HUD sounds |
| Voice | Master | — | Dialogue and narration |

_[Update effect chain details as configuration is finalized]_

---

## Music Ducking

_[Describe any sidechain compression or volume automation behavior — e.g., music ducks when voice plays]_

---

## Audio Manager API

See `docs/audio/audio-manager-api.md` for the full trigger function reference.
