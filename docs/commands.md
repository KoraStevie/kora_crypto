---
title: Commands
sidebar_position: 3
---

# Commands

## `/checkCrypto` (client)

Registered in `client/client.lua`, available to every player (no ACE restriction). It reads the player's `money.crypto` from `kora_core:getPlayerData()`, multiplies it by `GlobalState.Qbit.Worth` (rounded up) and shows a success notification with the Qbit amount and its dollar value.

No other commands are registered.
