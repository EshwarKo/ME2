# Phase 3 — Make (one)

The first phase that *produces*. Given "make N of item X", the system feeds a recipe's inputs
from storage into the crafter's input, waits for the product to appear, and collects it back —
without OC ever crafting anything itself. It only **feeds and polls** (charter §4).

One recipe at a time. No dependency tree, no "make the ingredients too" — that is Phase 4+.

## The idea

A recipe is plain, hand-authored data (`recipes.cfg`): `{ output, inputs }`, where each item is a
human-readable **label/name query**, not a hash. Queries bind to identity **late** — resolved at
make-time against the registry (charter §5) — so a recipe reads clearly and works in any world
once storage has seen the items.

Making one batch is:

1. **Scan** storage → fresh index (the cache is re-earned every batch).
2. **Plan** (pure): resolve each input query to a key, check storage has enough. Any unknown or
   under-stocked input is a shortage → fail loud, listing exactly what's missing.
3. **Feed**: move each input from `storage` → `craft_input` via the Phase 2 mover. A short move
   means the world drifted mid-feed → stop rather than craft a partial batch.
4. **Poll** `craft_output` until it is non-empty **and stable** across two polls (settled), or
   time out.
5. **Collect**: drain `craft_output` → `storage`, again via the mover.

Steps 3 and 5 reuse `me2.adapter.actuator` unchanged — feeding and collecting are the same
identity-verified move in opposite directions.

## Empty-chest baseline

Before making, both craft chests **must be empty** (fail loud otherwise). This is what lets us
attribute a later non-empty `craft_output` unambiguously to *this* craft, and keeps leftover
inputs from being mistaken for product. World-is-truth, no silent guessing (charter §3).

## Done-detection

There is no "crafting finished" signal from the world, so we infer it: the output is done when
it has appeared **and stopped growing** (two consecutive polls agree on a non-zero total). Poll
interval and timeout are `POLL`/`TIMEOUT` in `bin/make.lua`. A timeout fails loud. This is a
heuristic — a slow multi-stage machine that stalls mid-run could settle early — and is honest
about being one; a status-aware detector is a later refinement.

## Module map (added this phase)

```
src/me2/craft/recipes.lua   pure   find(list, query): recipes whose output matches a query
src/me2/craft/makeone.lua   pure   plan(recipe, index, resolve): inputs/output/shortages/ok
bin/make.lua                game   runnable: find recipe, feed inputs, poll, collect, report
config/recipes.example.cfg          the hand-authored recipe list
```

`makeone.plan`'s only world contact is injected:

```
resolve(query) -> key | nil     identity for a query, nil if unknown (raises on ambiguity)
index:count(key) -> n           how much storage holds
```

so the resolution, shortage accounting, and output defaulting are all proven offline.

## Reach

`storage`, `craft_input`, and `craft_output` must all share one transposer (direct moves). If
they don't, `make` fails loud — cross-transposer routing needs a shared buffer, a later concern.
On the single-transposer rig every role shares it.

## Run it

```sh
# offline
busted && luacheck src bin spec

# in-game (after update.lua + roles.cfg + recipes.cfg)
make "iron plate"        # make 1
make "iron plate" 8      # make 8 batches
```

`query` matches a recipe by an output label/name substring; ambiguous matches list the
candidates and abort. Input queries resolve against the registry the same way.

## Next

**Make (many)** — a dependency tree: when an input is itself craftable and out of stock, make it
first. Needs recursion, cycle detection, and a plan that batches sub-crafts before the final one.
