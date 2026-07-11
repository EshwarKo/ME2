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

## Development

Pure logic (the planner especially) is written to run and be tested **outside the game** with
`busted`, using injected/mocked adapters. Lint with `luacheck`.

```sh
luacheck .
busted
```
