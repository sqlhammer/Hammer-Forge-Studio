# Audio Technical Specifications

**Owner:** audio-engineer
**Status:** Draft
**Last Updated:** —

> Format requirements for all audio assets. No audio file may be added to the project without meeting these specs.

---

## File Formats

| Use Case | Format | Notes |
|----------|--------|-------|
| Music (streaming) | `.ogg` | Loop-enabled in import settings |
| SFX (short, loaded) | `.wav` or `.ogg` | `.wav` for <1s; `.ogg` for longer |
| Voice / dialogue | `.ogg` | |
| Ambient loops | `.ogg` | Loop-enabled in import settings |

---

## Sample Rates

| Use Case | Sample Rate |
|----------|------------|
| All audio | 44,100 Hz (44.1kHz) |

---

## Normalization Targets

| Category | Target Loudness |
|----------|----------------|
| SFX | _[TBD] LUFS integrated_ |
| Music | _[TBD] LUFS integrated_ |
| Voice | _[TBD] LUFS integrated_ |

---

## Naming Convention

`<category>_<descriptor>_<variant>.<ext>`

Examples: `sfx_footstep_stone_01.ogg`, `music_dungeon_ambient.ogg`, `ui_button_click.wav`

---

## Loop Points

All looping audio must have loop points set in Godot's import settings (not as metadata in the file). Confirm loop points produce no audible pop before submitting.

---

## Asset Location

All audio source files: `game/assets/audio/<category>/`
Categories: `music/`, `sfx/`, `ambient/`, `voice/`, `ui/`
