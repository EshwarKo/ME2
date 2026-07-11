# ME2

A purist reimplementation of an Applied Energistics 2 **ME storage-and-crafting system**,
written entirely in **OpenComputers Lua** for **GregTech: New Horizons** (Minecraft 1.7.10).

The point isn't speed — it's owning the whole intelligence. Every decision (what exists,
where it is, what to make next, when to restock) is made by code in OpenComputers. No AE2,
no logistics mods doing logic, no crafting robots. OC routes items; dumb GregTech machines
do the transforming (feed inputs, poll outputs).

## Documents

- **[CHARTER.md](CHARTER.md)** — the project's philosophy and unbreakable rules. Read first.
- **[CLAUDE.md](CLAUDE.md)** — the engineering guide: architecture stance, verified
  OpenComputers APIs, build order, tooling, conventions.

## Build order

Knowing → taking → making one → making trees → keeping in stock → interface → distribution.
Each layer ships working on its own.

## Development loop

Three tiers, fastest first — most work should happen without launching Minecraft.

1. **Pure logic (no game).** The planner and all decision logic run and are tested on your
   machine with `busted`, using injected/mocked adapters. Lint with `luacheck`.
   ```sh
   luacheck .
   busted
   ```
2. **In-game integration — live pull from GitHub.** Put an **Internet Card** in the OC
   computer, then bootstrap the updater once:
   ```
   wget -f https://raw.githubusercontent.com/EshwarKo/ME2/main/tools/update.lua /home/update.lua
   ```
   After every `git push`, run `update.lua` in the OC shell — it auto-discovers every `.lua`
   file in the repo (via the GitHub tree API) and mirrors it into `/home/me2`. No manifest to
   maintain. See `tools/update.lua` and `tools/me2.cfg.example`.
   - The one-line bootstrap above needs the repo to be **public**. While it's private, either
     flip it public (`gh repo edit EshwarKo/ME2 --visibility public --accept-visibility-change-consequences`)
     or drop a `token=` into `/etc/me2.cfg` and hand-place `update.lua` first.
   - `raw.githubusercontent.com` has a short CDN cache, so a fresh push can take a moment to
     appear — a few seconds, not a real blocker.
