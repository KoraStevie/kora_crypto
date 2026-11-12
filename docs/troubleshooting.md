---
title: Troubleshooting
sidebar_position: 8
---

# Troubleshooting

- **No target option at the exchange** - check `kora_target` is running and `Crypto.Exchange` is correct.
- **"You don't have a cryptostick"** - `qb-inventory` found no `cryptostick`. Make sure the item exists.
- **Crack is ignored with a console message** - the server printed `without a valid ticket` (`start again`, `too fast` or `expired`). The ticket comes from the target check; attempts must finish between 1.2 and 60 seconds later.
- **Handler assertion "too far"** - the player was more than 5.0 units from `Crypto.Exchange`.
- **Price never changes** - check the console for `Price update failed` or `kora_sql was unavailable`. The price only moves on a 0-100 roll outside the `ChanceOfDown`/`ChanceOfUp` band, so some updates are unchanged.
- **Price reset after restart** - it is restored from the `crypto` table; if the table was unavailable, the config `Worth` is used.
- **Missing translations** - the `notify.stick_lost` string exists only in `locales/en.lua`; other locales lack it.
