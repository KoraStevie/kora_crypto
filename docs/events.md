---
title: Events
sidebar_position: 4
---

# Events

The resource has no exports. The names below are internal to the exchange flow; do not trigger them from other resources.

## Callback

| Name | Side | Behaviour |
| --- | --- | --- |
| `qb-crypto:server:hasCryptoStick` | Server (`Kora.callback`) | Returns `true` if `qb-inventory` reports at least 1 `cryptostick` for the caller. When true it also starts a crack ticket. Returns `false` for invalid sources. |

## Server events

| Event | Behaviour |
| --- | --- |
| `qb-crypto:server:crackCryptoStick` | Requires the player within 5.0 of `Crypto.Exchange` (otherwise the handler asserts) and a valid ticket. Removes one `cryptostick`, credits a random 0.611111-1.599999 `crypto` money amount via `kora_core:addMoney`, then triggers `qb-phone:client:AddTransaction` with the credit message. |
| `qb-crypto:server:ExchangeFail` | Same distance and ticket checks, then removes one `cryptostick`. |

### Crack ticket

The minigame runs on the client, so the server cannot verify its result. To limit abuse, `hasCryptoStick` creates a per-player ticket. `crackCryptoStick` and `ExchangeFail` consume it and ignore the request (with a console message) if there is no ticket, if less than 1200 ms passed, or if more than 60000 ms passed. Tickets are cleared when the player drops. A client can still claim success without winning the minigame.

## Client events used

`qb-phone:client:AddTransaction` is triggered on the client of the player who cracked a stick. It is handled by `qb-phone`, not by this resource.

## State

`GlobalState.Qbit` is set by the server to a table with `Worth` (current price) and `History` (up to 4 entries of `PreviousWorth` and `NewWorth`). Other resources may read it.
