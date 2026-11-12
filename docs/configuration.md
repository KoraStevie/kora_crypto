---
title: Configuration
sidebar_position: 2
---

# Configuration

All settings are in the `Crypto` table in `shared/config.lua`. The table is passed through `Kora.config.adopt` when available, so server-side overrides from `kora_core` can replace values.

## Settings

| Key | Default | Meaning |
| --- | --- | --- |
| `Lower` | `500` | Price floor. |
| `Upper` | `5000` | Price ceiling. |
| `Worth` | `1000` | Starting price. Replaced by the stored value in the `crypto` table once it is read. |
| `Coin` | `'qbit'` | Row key in the `crypto` table. |
| `Exchange` | `vector3(1276.21, -1709.88, 54.57)` | Location of the crack target zone (1.0 x 1.0 x 1.0 box) and of the 5.0 distance check on the server. |
| `RefreshTimer` | `10` | Minutes between price updates. |
| `NotifyStickLost` | `true` | Notify the player when a failed minigame destroys the stick. |
| `NotifyNoStick` | `true` | Notify the player who tries to crack without a stick. |
| `ChanceOfCrashOrLuck` | `2` | Percent chance per update of a crash or luck event. |
| `Crash` | `{ 20, 80 }` | Min / max amount subtracted on a crash. |
| `Luck` | `{ 20, 45 }` | Min / max amount added on a luck event. |
| `ChanceOfDown` | `30` | A normal update goes down if a roll of 0-100 is less than or equal to this. |
| `ChanceOfUp` | `60` | A normal update goes up if the roll is greater than or equal to this. |
| `CasualDown` | `{ 1, 10 }` | Min / max amount subtracted on a normal down move. |
| `CasualUp` | `{ 1, 10 }` | Min / max amount added on a normal up move. |

`Crypto.qbit` and `Crypto.Labels` are present in the file but not read by any code.

## Price update rules

Each update rolls an event value from 1 to 100. If it is greater than `ChanceOfCrashOrLuck`, a normal move applies: a second roll of 0-100 moves the price down when at most `ChanceOfDown`, up when at least `ChanceOfUp`, and leaves it unchanged in between. Otherwise a coin flip applies a luck gain or a crash loss. The result is clamped to `Lower`..`Upper`.

The crack reward is not configurable: it is a random value from 0.611111 to 1.599999 Qbit, hard-coded in `server/server.lua`. The ticket timings (minimum 1200 ms, expiry 60000 ms) and the 5.0 distance are also hard-coded.
