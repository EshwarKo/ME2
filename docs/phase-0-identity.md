# Phase 0 — Identity

The foundation: give the system an exact, NBT-inclusive answer to *"is this the same item
as that?"* and *"what is this item?"*. Nothing later (knowing storage, taking, making) can be
trusted until this is right (CHARTER §5: *identity is sacred*).

## The idea

An item's **identity** is the hash produced by an OpenComputers **Database Upgrade**
(`computeHash`), which folds in the registry id, damage, and full NBT. We use the database
component purely as a **hashing oracle** — a dumb primitive — and keep our own registry as
the long-term store. The intelligence stays in OC (CHARTER §3).

A **descriptor** is the quantity-independent metadata behind a hash (name, label, damage,
maxDamage, maxSize, hasTag). It deliberately excludes stack *size*, which is inventory state,
not identity.

## Module map

```
src/me2/item/descriptor.lua   pure   what we cache about an item; equality; fromStack()
src/me2/item/registry.lua     pure   key -> descriptor cache; fails loud on identity conflict
src/me2/item/identity.lua     pure   location -> key, keeping the registry in step (DI: hasher)
src/me2/adapter/db_hasher.lua  game  implements the hasher via Database Upgrade + transposer
bin/identify.lua               game  runnable artifact: scan an inventory, print keys, persist
```

## The pure / adapter boundary

Everything interesting is pure and proven offline. `identity` depends on an injected
**hasher** with the contract:

```
hasher:hashAt(location) -> key, stack   -- item present
hasher:hashAt(location) -> nil, err      -- empty / unreadable
```

- In-game the hasher is `db_hasher` (does `transposer.store` → `computeHash` → `get`).
- In tests it is `spec/support/fake_hasher`, returning canned pairs — zero blocks placed.

This is the charter's mandate in miniature: prove the logic in isolation, then the rest is
plumbing (CHARTER §8).

## Guarantees enforced here

- **Same hash ⇒ same descriptor.** `registry:put` raises on any conflict rather than
  silently overwrite — a mismatch means hash corruption or an identity bug, and we fail loud.
- **Cache, not truth.** The registry serializes to `/home/me2/registry.db` and can be rebuilt
  by rescanning; it never claims authority over the world.
- **Roles, not addresses.** `identify.lua` takes a *side*; no UUIDs live in logic.

## Proven vs. deferred

- **Proven offline** (`busted`): descriptor extraction/equality, registry semantics incl.
  conflict + snapshot/restore, and the identify policy incl. stable re-identification and
  loud failure on collision.
- **Deferred to in-world verification:** whether `store` lives on `transposer` vs
  `inventory_controller` in this OC build, and GT machine slot quirks. `db_hasher` isolates
  that risk to one small file.

## Run it

```sh
# offline
busted && luacheck src bin spec

# in-game (after `update.lua` syncs the repo to /home/me2)
identify north
```
