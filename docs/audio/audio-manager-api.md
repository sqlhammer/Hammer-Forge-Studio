# Audio Manager API

**Owner:** audio-engineer
**Status:** Draft
**Last Updated:** —

> All in-game audio must be triggered through AudioManager autoload. Gameplay Programmer uses this reference — never call AudioStreamPlayer.play() directly from gameplay scripts.

---

## Usage

```gdscript
# Access the AudioManager autoload
AudioManager.play_sfx("sfx_footstep_stone_01")
AudioManager.play_music("music_dungeon_ambient")
AudioManager.stop_music()
```

---

## Functions

_[To be filled in by audio-engineer once audio_manager.gd is implemented by systems-programmer]_

### `play_sfx(sound_name: String, volume_db: float = 0.0) -> void`

_[Description]_

### `play_music(track_name: String, fade_in: float = 0.5) -> void`

_[Description]_

### `stop_music(fade_out: float = 0.5) -> void`

_[Description]_

### `set_bus_volume(bus_name: String, volume_db: float) -> void`

_[Description]_

---

## Signals

_[Signals emitted by AudioManager, if any]_

---

## Integration Notes

_[What Gameplay Programmer needs to know to trigger audio correctly]_
