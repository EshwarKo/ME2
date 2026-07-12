-- me2.adapter.db_hasher   (IN-GAME ONLY — not offline-testable by design)
--
-- Implements the identity hasher contract: copy a real stack into a scratch Database
-- Upgrade slot, then read the plain stack table back. We deliberately DO NOT call
-- database.computeHash: that hash is quantity-dependent (it hashes the stack's Count byte),
-- which would mint phantom duplicate identities. Identity is derived from the stack itself
-- by me2.item.keyof; this adapter only supplies the stack. The DB store gives a clean,
-- validated read (the `store` ok-flag is our "is anything here?" check).
--
--     stackAt(location) -> stack       location = { side = <sides.*>, slot = <n> }
--     stackAt(location) -> nil, err    when the slot is empty / unreadable
--
-- The stack table carries `oreNames` (oreDict classes) only when the OC config
-- `debug.insertIdsInConverters=true`, and `tag` (raw NBT bytes) only when
-- `integration.vanilla.allowItemStackNBTTags=true` -- both required for full identity.
--
-- Verify in-world: this uses transposer.store(side, slot, dbAddress, dbSlot). Some OC
-- builds expose `store` on inventory_controller instead; if so, inject that proxy as
-- `transposer` — the only method used here is `store`.

local DbHasher = {}
DbHasher.__index = DbHasher

local function new(transposer, database, scratchSlot)
  assert(transposer, "db_hasher.new: transposer proxy required")
  assert(database, "db_hasher.new: database proxy required")
  return setmetatable({
    _tp = transposer,
    _db = database,
    _dbAddr = database.address,
    _scratch = scratchSlot or 1,
  }, DbHasher)
end

function DbHasher:stackAt(location)
  local ok = self._tp.store(location.side, location.slot, self._dbAddr, self._scratch)
  if not ok then
    return nil, "db_hasher: nothing to read at side "
      .. tostring(location.side) .. " slot " .. tostring(location.slot)
  end
  return self._db.get(self._scratch)
end

return { new = new }
