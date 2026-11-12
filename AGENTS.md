# kora_crypto agent guide

`kora_crypto` is the Kora Qbit cryptocurrency resource: a server-wide coin price that moves on a timer and is persisted in the `crypto` table, plus a cryptostick exchange (`kora_target` zone and keys minigame) and the `/checkCrypto` command. Layout: `fxmanifest.lua`, `shared/config.lua` (`Crypto` config), `server/schema.lua` (table schema), `server/server.lua` (price loop, crack guards), `client/client.lua` (target zone, command), `locales/*.lua`, `test/` (offline Lua checks) and `tests/` (kora_qa feature files).

## Documentation

User-facing documentation lives in `docs/` (Markdown, published via the Kora Docusaurus site, kora_docs_next). Read `docs/index.md` first for an overview of features, configuration, commands, events, items and database usage.

When you add, change, or remove a feature, config option, command, export, event, item, permission, or database table/column, update the matching page in `docs/` in the same change. Keep docs accurate to the code; do not document behaviour that does not exist.

Docs rules: plain Markdown with `title`/`sidebar_position` front matter (no `id`/`slug`), relative links only between docs pages, assets inside `docs/`, fenced code blocks with a language, and no raw `<`, `>`, `{`, `}` outside code (pages are parsed as MDX). The release version comes from `fxmanifest.lua`'s `version` field.

## Shared contribution standards

Read [CONTRIBUTING.md](CONTRIBUTING.md) before editing. Humans and agents follow
the same Kora standards and self-contained local Lua checks. Preserve the domain
constraints above and in module guides; record policy conflicts explicitly.

Copyright © 2026 Kora Framework (new contribution guidance).
