# State Dump Reference

## Overview

The debug state dump is triggered by the `debug_state_dump` input action (F12 key). When pressed, `Global.gd` prints a structured block of key-value pairs to the Godot console. The play-tester agent reads this output via `get_godot_errors`.

## Triggering

```
simulate_input("debug_state_dump", "press")
```

Then immediately call `get_godot_errors()` to read the output.

## Output Format

```
[12345] === STATE_DUMP_BEGIN ===
[12346] PLAYER_POS: (12.0, 3.5, -8.0)
[12347] PLAYER_ON_FLOOR: true
[12348] PLAYER_VELOCITY: (0.0, -0.1, 0.0)
[12349] BIOME: shattered_flats
[12350] BATTERY: 0.95
[12351] INVENTORY_USED: 3
[12352] FUEL: 8.0
[12353] === STATE_DUMP_END ===
```

## Parsing

1. Find lines between `STATE_DUMP_BEGIN` and `STATE_DUMP_END`
2. Strip the `[timestamp]` prefix from each line
3. Split each line on `: ` (colon-space) to get key and value
4. Parse values by type (see below)

## Field Reference

| Field | Type | Source | Description |
|-------|------|--------|-------------|
| `PLAYER_POS` | Vector3 string `(x, y, z)` | Player node `global_position` | Player world position. Y > 0 means above origin. |
| `PLAYER_ON_FLOOR` | `true` / `false` | `CharacterBody3D.is_on_floor()` | Whether player is grounded. |
| `PLAYER_VELOCITY` | Vector3 string `(x, y, z)` | `CharacterBody3D.velocity` | Current velocity. Y near 0 = stable. |
| `BIOME` | String | `NavigationSystem.current_biome` | Active biome name (e.g., `shattered_flats`, `rock_warrens`, `debris_field`). |
| `BATTERY` | Float (0.00–1.00) | `SuitBattery.get_charge_percent()` | Suit battery as percentage. |
| `INVENTORY_USED` | Int (0–15) | `PlayerInventory.get_used_slot_count()` | Number of occupied inventory slots. |
| `FUEL` | Float | `FuelSystem.fuel_current` | Current fuel level. |

## Notes

- The state dump only works in debug builds (`OS.is_debug_build()`)
- If the Player node is not found (e.g., in a menu scene), PLAYER_POS/ON_FLOOR/VELOCITY lines will be absent
- The dump captures a single frame's state — trigger it after actions have settled (wait 1-2 seconds after movement)
