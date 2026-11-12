---
title: kora_crypto
sidebar_position: 1
---

# kora_crypto

`kora_crypto` provides the Qbit cryptocurrency for Kora servers. A single coin (`qbit`) has a server-wide price that drifts on a timer and is stored in the database. Players earn Qbit by cracking `cryptostick` items at a fixed exchange location (a `kora_target` zone plus a keys minigame), and can check the dollar value of their Qbit with `/checkCrypto`. It keeps the legacy `qb-crypto:*` event names.

Current version: see `version` in `fxmanifest.lua`.

## Features

- **Price simulation** - every `Crypto.RefreshTimer` minutes the server moves the price, clamps it to `Crypto.Lower`..`Crypto.Upper`, saves it and publishes it in `GlobalState.Qbit`. See [Configuration](./configuration.md).
- **Price history** - the last 4 price changes are kept and published with the price.
- **Persistence** - price and history live in the `crypto` table and are restored on resource start. See [Database](./database.md).
- **Cracking cryptosticks** - at the exchange, the "Crack Crypto Stick" target option checks for a stick, runs the keys minigame, then credits a random 0.611111 to 1.599999 Qbit and consumes the stick. A failed minigame destroys the stick. See [Events](./events.md).
- **Server-side guards** - crack events need the player within 5.0 units of the exchange and a single-use, time-bounded ticket.
- **Phone transaction** - a successful crack triggers `qb-phone:client:AddTransaction`.
- **`/checkCrypto`** - see [Commands](./commands.md).
- **Locales** - strings in `locales/*.lua`; see [Troubleshooting](./troubleshooting.md) for gaps.

## Pages

- [Configuration](./configuration.md)
- [Commands](./commands.md)
- [Events](./events.md)
- [Items](./items.md)
- [Database](./database.md)
- [Dependencies and installation](./installation.md)
- [Troubleshooting](./troubleshooting.md)

The resource exposes no exports and no NUI.
