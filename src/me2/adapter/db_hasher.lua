-- me2.adapter.db_hasher   (IN-GAME ONLY — not offline-testable by design)
--
-- Implements the identity hasher contract using a Database Upgrade as a pure hashing
-- oracle: copy a real stack into a scratch DB slot, compute its NBT-inclusive hash, then
-- read the stack table back. The database component is used ONLY to hash — our own
-- registry is the long-term store. This keeps the intelligence in OC and treats the
-- component as the dumb identity primitive the charter describes (§2, §3).
--
--     hashAt(location) -> key, stack        location = { side = <sides.*>, slot = <n> }
--     hashAt(location) -> nil, err          when the slot is empty / unreadable
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

function DbHasher:hashAt(location)
  local ok = self._tp.store(location.side, location.slot, self._dbAddr, self._scratch)
  if not ok then
    return nil, "db_hasher: nothing to hash at side "
      .. tostring(location.side) .. " slot " .. tostring(location.slot)
  end
  return self._db.computeHash(self._scratch), self._db.get(self._scratch)
end

return { new = new }
