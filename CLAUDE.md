# CLAUDE.md — ME2

Engineering guide for **ME2**: a purist reimplementation of an AE2 ME storage-and-crafting
system, written entirely in OpenComputers Lua for GregTech: New Horizons.

Read `CHARTER.md` first. It is the project's constitution. This file is *how* to build;
the charter is *what* and *why*. When this file and the charter conflict, **the charter wins.**

---

## Unbreakable rules (from the charter — do not violate)

1. **OC owns all intelligence.** No storage, routing, or crafting decision may be delegated
   to AE2, Logistics Pipes, EnderIO conduits, Steve's Factory Manager, or any other mod's
   built-in logic. If a thing could be done by writing Lua or by leaning on another mod's
   brain, **write the Lua.**
2. **Feed-and-poll is the only crafting primitive.** OC never assembles a recipe. It places
   inputs into a dumb producer (a GregTech machine, or a dumb auto-crafter for vanilla
   recipes) and later collects the output. No crafting robots, no internal crafting grids.
3. **Identity is sacred.** Two stacks are the same only if truly identical *including NBT*.
   Never merge distinct stacks (circuits, cells, tools, filled containers).
4. **World is truth; the in-memory model is only a cache.** Always be able to reconcile
   against the world; never trust the cache when they disagree.
5. **Fail loud.** A halted system with a visible error beats one that runs while silently
   corrupting its own picture. `error()` / `assert()` over guessing.
6. **Hardware is a late binding.** Address blocks by *role* ("storage", "assembler",
   "output"), never by hardcoded UUID or quantity, inside recipes/plans.
7. **Always runnable.** Every layer stands alone and does something useful. No big-bang build.

---

## Environment (fixed facts)

- **Modpack:** GregTech: New Horizons **2.9.0-beta-1**, **Minecraft 1.7.10**.
- **Runtime:** OpenComputers (GTNH fork), **OpenOS**, **Lua 5.3** (assume 5.3; some builds
  fall back to 5.2 — do not rely on `<close>`/to-be-closed vars or 5.4 features).
- **Prototyping tier:** Creative computer. CPU/RAM/energy/tick limits are effectively
  infinite *for now*. Do not design around scarcity yet, but keep the design remappable.

---

## Architecture stance (mandated for testability)

Split every module into two kinds:

- **Pure logic** (planner, dependency-tree resolver, identity/model bookkeeping,
  reconciliation): **no `require("component")`, no `require("event")`, no I/O at load
  time.** These take data in and return data/decisions out. This is where the interesting
  work lives and it must be **testable outside the game** (see Testing).
- **OC adapters** (thin): wrap `transposer`, `database`, `modem`, `gpu`/`term`, GregTech
  machine inventories via adapters. They translate between the world and plain Lua tables.

**Dependency injection:** pure logic receives its adapters as arguments, never reaches for
globals. This is what lets the planner be proven on invented stock/recipe data with zero
blocks placed (charter §8).

Prove the **crafting-request → ordered plan** resolver in isolation first. If it is correct
on paper, the rest is plumbing.

---

## Key OpenComputers APIs (verified signatures)

### Item identity — use the `database` component, not raw stacks
Raw stacks from `transposer.getStackInSlot(side, slot)` do **not** carry a reliable NBT
hash. Fields present: `name` (registry id), `label`, `damage`, `maxDamage`, `size`,
`maxSize`, `hasTag` (bool — NBT present), `isCraftable`. Full NBT is not exposed as
readable Lua, so **string-keying on `name..damage` is lossy and forbidden** by rule 3.

Correct identity workflow (AE2-style unique key):
```lua
-- transposer writes a real stack into a database upgrade slot, then hash it
transposer.store(side, slot, dbAddress, dbSlot)   -- boolean
local hash = database.computeHash(dbSlot)          -- stable, NBT-inclusive identity key
local idx  = database.indexOf(hash)                -- slot index, or negative if absent
local stk  = database.get(dbSlot)                  -- table
database.copy(fromSlot, toSlot[, otherDbAddress])  -- boolean
database.clone(otherDbAddress)                      -- number
```
`computeHash` returns identical strings for identical stacks including NBT — this is the
identity primitive the charter refers to. Treat the hash as the canonical item key everywhere.

### Moving items — `transposer`
```lua
transposer.transferItem(sourceSide, sinkSide, count, sourceSlot, sinkSlot) -- returns count moved
transposer.getInventorySize(side)
transposer.getSlotStackSize(side, slot)
transposer.getStackInSlot(side, slot)
transposer.getAllStacks(side)   -- iterator: :getAll(), :count(), :reset(), :next()
```
Sides via `require("sides")`: `down=0, up=1, north=2, south=3, west=4, east=5`. Movement is
only between inventories physically adjacent to the transposer (charter: respect reach).

### Components
```lua
local component = require("component")
component.proxy(address)            -- full proxy table
component.list([filter[, exact]])   -- iterator of address→type
component.get(partialAddress[, type])
component.isAvailable(type); component.getPrimary(type)
component.<type>                     -- shortcut to the primary of that type
```
Addresses are full UUIDs. **Never hardcode a UUID in logic** — resolve by role at the adapter
boundary and pass the proxy in (rule 6).

### GregTech machines
An **adapter** block placed adjacent to a GT machine exposes that machine's inventory to the
transposer / `inventory_controller`. Quirks to design around:
- GT inventory calls are **indirect and slow (~1 server tick each)** — batch and cache, never
  full-rescan every tick.
- GT machines have input / output / **programmed-circuit** slots. The circuit slot holds a
  config item; treat it specially and verify in-world whether `transferItem` into it behaves.
- Whether a given machine accepts/ejects via a given side is machine- and cover-dependent —
  discover it, do not assume.

### Networking (for later multi-computer distribution)
```lua
local modem = component.modem
modem.open(port); modem.send(address, port, ...); modem.broadcast(port, ...)
-- receive:
local _, _, from, port, dist, a, b = event.pull("modem_message")
```

### Events / persistence
```lua
local event = require("event")
event.pull([timeout,] name, ...)      -- yields; use in the main loop
os.sleep(sec)                          -- yields (pulls events internally)
local ser = require("serialization")
ser.serialize(t[, pretty]); ser.unserialize(s)   -- persist model/recipes to disk via io.open
```

---

## Performance & correctness constraints

- **Yield or die.** ~5s without yielding → "too long without yielding" abort. Long loops must
  call `os.sleep(0)` / `event.pull(0)` periodically. Any loop that scans inventories or drives
  producers must yield.
- **Indirect calls cost a full tick** (most world/inventory/GT reads). Minimize them: cache
  hashes, avoid per-tick full rescans, reconcile incrementally.
- On Creative tier energy/budget is effectively infinite — but write loops as if they weren't,
  so the hardware-mapping pass is a remap not a rewrite.

---

## Build order (each layer ships working — charter §8)

1. **Identity** — nail the hash-based item key against a real database component. Nothing else
   is trustworthy until this is exact.
2. **Know** — an accurate, reconcilable in-memory picture of storage ("what do I have, where").
3. **Take** — give out items on request.
4. **Make (one)** — feed-and-poll a single producer end-to-end for one recipe.
5. **Make (tree)** — the planner: resolve a request's full dependency tree into a valid ordered
   plan against current stock, drive producers, report progress/failure. **Prove pure, offline,
   first.**
6. **Keep in stock** — automatic restocking of chosen items.
7. **Interface** — a human-pleasant UI.
8. **Distribution** — optional multi-computer split over the modem.

Do not start a layer before the one under it works.

---

## Lua conventions

- One module per file, `local M = {} ... return M`. `local` everything; no accidental globals.
- Pure-logic files must not touch `component`/`event`/`io` at require time.
- Errors: `error("context: what and why")` or `assert(cond, msg)`. No silent `nil` returns for
  failure states that matter (rule 5).
- Item keys are database hashes, everywhere. No `name..":"..damage` keys.
- Roles, not addresses, in any recipe or plan structure.

---

## Tooling

- **Lint:** `luacheck` with the project `.luacheckrc` (declares OC globals/libs so they aren't
  flagged). Run before every commit.
- **Test:** `busted` for pure-logic modules. Mock adapters as plain Lua tables and inject them —
  no game required. The planner in particular must have a full offline test suite driven by
  invented stock + recipe fixtures.
- Keep tests green; per global instructions, **verify — never assume it works.**

---

## Workflow (inherits global CLAUDE.md)

- Feature branches; conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`,
  `chore:`) with a scope when clear (`feat(planner): ...`).
- Non-trivial work (3+ steps): explore and plan before coding; use subagents for research.
- When a design choice is unclear, pick the option that keeps intelligence in OC, keeps item
  identity exact, respects physical reach, and stays understandable. Build it so the author can
  explain every part.
