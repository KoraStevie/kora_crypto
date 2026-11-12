---
title: Dependencies and installation
sidebar_position: 7
---

# Dependencies and installation

## Declared dependencies

`fxmanifest.lua` declares `kora_lib`, `kora_core`, `kora_sql` and `kora_target`.

## Used but not declared

- `qb-inventory` - `HasItem` and `RemoveItem` exports.
- `qb-phone` - receives `qb-phone:client:AddTransaction` (optional in practice; the event is simply unhandled without it).

## Installation

1. Start the resource after its dependencies and `qb-inventory`.
2. Make sure the `cryptostick` item exists.
3. Adjust `shared/config.lua` if needed. The table is created automatically.

## Tests

`lua test/smoke/crypto_sql.lua` (needs the sibling `kora_core` and `kora_sql` repositories) checks pricing and persistence with an in-memory SQL driver. `lua test/credit.lua` checks the credit path with mocks. `tests/checklist-economy.feature` holds manual `kora_qa` scenarios.
