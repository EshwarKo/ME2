# Phase 1 — Know

Building on identity (Phase 0): an accurate, reconcilable picture of storage. The system can
now answer *what do I have, how many, and in which slots* — the knowledge every later phase
(Take, Make, Keep-in-stock) depends on.

## The idea

Scanning a storage inventory produces a **fresh index** that mirrors the world. The index is
a cache (charter §5): we rebuild it by scanning rather than trusting a persisted count, so it
can never drift from reality and quietly be wrong. Items are keyed by identity hash, so
distinct-but-similar stacks are never merged.

## Module map (added this phase)

```
src/me2/storage/index.lua          pure   slot -> {key,count}; derived count()/locations()/keys()
src/me2/storage/scan.lua           pure   reconcile: read a source -> fresh index (world is truth)
src/me2/adapter/storage_source.lua  game  a transposer side as a scan source (identity + count)
bin/inventory.lua                   game  runnable: scan a role, print totals per item
```

## The pure / adapter boundary

`scan.run` depends on an injected **source**:

```
source:size()        -> number of slots
source:slotAt(slot)  -> key, count      (nil when empty)
```

- In-game the source is `storage_source` (transposer count + `me2.item.identity` for the key,
  which also teaches the registry the descriptor behind each hash).
- In tests it is a fake inventory table — the whole index+reconcile is proven offline.

## What the index guarantees

- **count(key)** and **locations(key)** stay in step with per-slot writes, so Take can pick
  slots to pull from without rescanning.
- **Fresh mirror each scan.** A player moving items just means the next scan corrects the
  picture; a mid-scan yank yields a count the next scan fixes (the index is a cache, not a lock).
- Registry (identity descriptors) persists to `/home/me2/registry.db`; the index itself is
  transient truth, always rebuilt.

## Run it

```sh
# offline
busted && luacheck src bin spec

# in-game (after update.lua + a filled /home/me2/roles.cfg)
inventory              # scans the `storage` role
inventory craft_output # or any bound role
```

## Next

**Take** — pull N of an item out of storage into an output, using `index:locations(key)` to
choose slots and the transposer to move them. This is the first phase that *changes* the world.
