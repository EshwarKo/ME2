# ME2 — Project Philosophy & Charter

*A purist OpenComputers reimagining of an ME system, for GregTech: New Horizons.*

This document is a **philosophy, not a design**. It exists to be handed to a fresh
implementing session (e.g. Claude Code) so that session can build the project from
first principles. It deliberately contains **no system architecture** — no module
layout, no data structures, no code, no chosen topology. Those decisions belong to
the implementer. What follows is the *why*, the *what*, and the *unbreakable rules*.
Everything else is yours.

---

## 1. What this project is

The goal is to rebuild the **intelligence** of an AE2 ME system entirely inside
OpenComputers, from scratch, for the joy and challenge of understanding every part
of it.

This is not an attempt to beat AE2 on speed or convenience. It is an attempt to own
the whole thing — to have a storage-and-crafting brain whose every decision we wrote
ourselves and can hold in our heads. The reward is comprehension and craftsmanship,
not throughput.

Treat "for fun" as a real engineering requirement, not a disclaimer. It means the
system should be **understandable** above all, and that a slower, simpler design that
the author fully grasps always beats a clever one they don't.

---

## 2. The environment you are building in

These are fixed facts, not choices:

- **Pack:** GregTech: New Horizons, version **2.9.0-beta-1**. **Minecraft 1.7.10.**
- **Language/runtime:** the **OpenComputers** mod (the GTNH fork), programmed in Lua.
- **Prototyping stance:** development happens first on a **Creative-tier computer**
  where CPU, RAM, energy, and per-tick limits are effectively infinite. **Hardware is
  deferred.** Real-hardware constraints (component tiers, energy, quantity, placement)
  are a *later mapping pass*, not a present concern. Design so that pass is a remap,
  not a rewrite.
- **GTNH is machine-recipe-heavy.** Most intermediate items are produced by GregTech
  *machines*, not by vanilla 3×3 crafting. This shapes what "making something" means
  here (see §4).

What the environment *gives* you as raw capability (stated as fact, not as a design):
programmable computers with screens and networking; the ability to move items between
directly-adjacent inventories; a primitive that produces a stable identity hash for an
item stack including its NBT; and dumb machines/inventories that transform and hold
items. How you compose these is entirely your call.

---

## 3. The prime directive: OpenComputers owns the mind

**All intelligence lives in OpenComputers. Nothing else gets to think.**

Other mods may provide only *dumb bodies*: inventories that hold items, machines that
transform them on demand. Every decision — what exists, where it is, what to make next,
how to present it, when to restock — is made by code we wrote, running in OC.

This single line is what "purist" means, and it is non-negotiable. Concretely, it rules
out:

- **AE2** — the very thing being replaced.
- **Any other logistics/automation mod doing logic** (Logistics Pipes, Steve's Factory
  Manager, EnderIO, conduits with built-in routing/crafting, etc.). They may not own
  storage, routing, or crafting decisions.
- **Crafting robots.** OC does not craft with its own hands (see §4).

If a capability could be satisfied either by writing OC logic or by leaning on another
mod's built-in brain, **write the OC logic.** That friction is the point of the project.

---

## 4. OpenComputers routes; it does not craft

The system's role in *making* things is strictly: **put the right ingredients in some
place, then wait for the result to appear in some place, then take it.** The act of
transformation belongs to dumb blocks — GregTech machines for the machine recipes that
dominate GTNH, and a dumb auto-crafting block for the residual vanilla recipes.

OC never assembles a recipe itself. No robot arms, no internal crafting grids. "Feed an
input, poll an output" is the *only* crafting primitive, applied uniformly to every kind
of producer. This keeps the system deterministic, keeps the intelligence in the planner
rather than the actuator, and matches how GTNH's machines already work.

The planner's job is the hard, interesting part: given a request, resolve the full tree
of what must be made and in what order, then drive the dumb producers to fulfill it.

---

## 5. The principles (the doctrine)

These guide every judgment call the implementer makes.

**Correctness over speed.** Throughput is an explicit non-goal. Deliberate and slow is a
virtue, not a compromise. Never trade clarity or correctness for performance.

**The world is the source of truth; any model is only a cache.** OC will keep a picture
of reality in memory, but reality can change without asking (a player moves items). The
system must be able to reconcile its picture with the world and must never trust the
cache over the world when they disagree.

**Identity is sacred.** Two items are "the same" only if they are truly identical,
including NBT. The system must never merge things the game keeps distinct (circuits,
cells, tools, filled containers). Get item identity exactly right *before* building
anything that depends on it — it is the foundation the whole system stands on.

**Respect physical reach.** Movement is local and physical, not magical: things can only
move between places that can physically touch. The shape and limits of the system follow
from this. Do not design as if items teleport.

**Hardware is a late binding.** Express the system in terms of *roles and intentions*
("an assembler", "storage", "the output"), and bind those to specific blocks or addresses
as late as possible. Recipes and plans must stay valid when the hardware changes. Prototype
where nothing is scarce, then map.

**Fail loud, never silently wrong.** A halted system with a visible error is far better
than one that keeps running while quietly corrupting its own understanding. Prefer to stop
and surface a problem over guessing.

**Always runnable.** Build in layers, each of which stands alone and does something useful
on its own. Never a long march to a big-bang first launch. Knowing-what-you-have should
work before taking things; taking should work before making; making one thing should work
before making anything.

**Understandability is the deliverable.** When two designs are otherwise close, choose the
one the author can fully explain. Cleverness that outruns comprehension is a defect here.

---

## 6. What the system must eventually be able to do

Capabilities, stated as goals — the *how* is left open:

- Know everything currently in storage, and where each thing is.
- Accept new items arriving into the system and file them away.
- Give out items on request.
- Make items on request: resolve the complete dependency tree for a requested item
  against current stock, then drive the dumb producers to build it, in a valid order,
  reporting progress and failures.
- Keep chosen items automatically in stock.
- Present all of the above through an interface a human actually enjoys using.

A design is "complete enough" when these hold and the author understands every step.

---

## 7. Explicit non-goals and anti-patterns

Do **not**:

- Optimize for throughput or item-moving speed.
- Delegate any *decision* to another mod's built-in logic.
- Use crafting robots or any OC-side crafting; crafting is always feed-and-poll to a dumb
  block.
- Depend on AE2 for anything in the working system.
- Hardcode block addresses or hardware quantities into recipes or plans.
- Allow lossy item identity that merges non-identical stacks.
- Pursue a monolithic build that only works once every part is finished.

---

## 8. How to approach the build

Move from **knowing** to **acting**: first make the system *know* the world (identity +
an accurate picture of storage), because everything else depends on trustworthy knowledge.
Only then add *taking*, then *making*, then *keeping in stock*, then the *interface* polish
and any *distribution* across multiple computers.

Prove the hardest pure-logic component — resolving a crafting request into an ordered plan
— **in isolation, against invented stock and recipe data**, before wiring it to anything in
the world. It is pure computation; it should be testable with zero blocks placed. If the
planner is right on paper, the rest is plumbing.

Keep everything hardware-agnostic (per §5) so that graduating from the creative prototype to
real hardware is a matter of binding roles to blocks, not rewriting logic.

---

## 9. A note to the implementing session

You have full latitude over architecture: how you structure code, what data you keep, how
you name and separate concerns, which patterns you use, how the interface looks. Those
choices are yours to make well.

What is **not** yours to change is this charter — the prime directive (§3), the feed-and-poll
crafting rule (§4), and the principles (§5). When a decision is unclear, choose the option
that keeps the intelligence inside OpenComputers, keeps item identity exact, respects that
items move physically and locally, and keeps the whole thing understandable to the person who
has to maintain it.

Build it so its author can explain every part. That is the point.
