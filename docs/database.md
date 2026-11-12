---
title: Database
sidebar_position: 6
---

# Database

The table is created or checked at start by `kora_sql` (`Kora.sql.ensureTables`) from `server/schema.lua`. No SQL files are shipped.

## `crypto`

| Column | Type | Default | Notes |
| --- | --- | --- | --- |
| `crypto` | `varchar(50)` | `qbit` | Primary key; matches `Crypto.Coin`. |
| `worth` | `int` | `0` | Current price. |
| `history` | `text` | `NULL` | JSON array of `{ PreviousWorth, NewWorth }`, at most 4 entries. |

A seed row is inserted for `qbit` with worth 1000 and one history entry.

## Behaviour

- On start, after `kora_sql` is ready (60 s wait), the row is read and the price and history are published in `GlobalState.Qbit`.
- Each price update runs an `UPDATE`; if no row was affected an `INSERT` is made. Failures are printed to the console and the update is skipped.
- The player's Qbit balance is not stored here; it belongs to `kora_core` money.
