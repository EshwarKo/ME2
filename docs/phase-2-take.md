# Phase 2 — Take

The first phase that *changes* the world. Given "give me N of item X", the system chooses
storage slots, moves the items to a destination, and reports exactly what it managed to give.

The move primitive here (source role → dest role, identity-verified) is deliberately the same
one **Make** will reuse to feed ingredients into a producer.

## The idea

Take reconciles first (a fresh scan → index), plans the withdrawal purely, then executes each
move through an actuator that **re-checks the slot's identity immediately before moving**. The
index is a cache; the world can shift between scan and move, so we never hand out a slot that
no longer holds the requested item (charter §3, §5). A partial result is reported, not hidden.

## Module map (added this phase)

```
src/me2/storage/give.lua       pure   plan() picks slots; run() executes via an actuator
src/me2/adapter/actuator.lua    game  move items between two sides of one transposer; keyAt()
bin/take.lua                    game  runnable: resolve a query -> key, scan, give, report
```

## The pure / adapter boundary

`give.run` depends on an injected actuator:

```
actuator:keyAt(slot)       -> key | nil     current identity of a source slot
actuator:move(slot, count) -> moved          move up to count out; returns actual moved
```

- In-game the actuator is `me2.adapter.actuator` (transposer `transferItem` + identity check).
- In tests it is a fake that can simulate identity drift and partial physical moves — so the
  greedy selection, the skip-on-drift, and the shortfall accounting are all proven offline.

## Reach

Source and destination roles must share one transposer (a direct move). If they don't, `take`
fails loud rather than silently doing nothing — cross-transposer routing needs a shared buffer,
which is a later concern. On the current single-transposer rig every role shares it, so any
role pair works.

## Run it

```sh
# offline
busted && luacheck src bin spec

# in-game (after update.lua + roles.cfg)
take "iron ingot" 32                 # storage -> craft_output (defaults)
take <hash> 8 craft_input storage    # exact key, explicit dest + source
```

`query` matches an item label/name substring (or an exact identity key); ambiguous matches
list the candidates and abort.

## Next

**Make (one)** — feed a producer's input, poll its output: reuse the mover to place ingredients
into `craft_input`, wait for `craft_output` to fill, then take the result. Still one recipe,
no dependency tree yet.
