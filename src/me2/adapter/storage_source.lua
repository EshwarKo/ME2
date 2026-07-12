-- me2.adapter.storage_source   (IN-GAME ONLY -- not offline-testable by design)
--
-- Presents one inventory (a transposer side) as a scan source: yields (key, count) for each
-- occupied slot. Identity comes from me2.item.identity (which also teaches the item registry
-- the descriptor behind each hash); the count comes straight from the transposer.
--
--   size()       -> transposer.getInventorySize(side)
--   slotAt(slot) -> key, count  |  nil when empty
--
-- Note: this reads the slot count and hashes it as two calls, so a player yanking an item
-- mid-scan just yields a count the next scan corrects -- the index is a cache, not a lock.

local StorageSource = {}
StorageSource.__index = StorageSource

local function new(transposer, identity, side)
  assert(transposer, "storage_source.new: transposer proxy required")
  assert(identity, "storage_source.new: identity required")
  assert(type(side) == "number", "storage_source.new: side must be a number")
  return setmetatable({ _tp = transposer, _id = identity, _side = side }, StorageSource)
end

function StorageSource:size()
  return self._tp.getInventorySize(self._side)
end

function StorageSource:slotAt(slot)
  local count = self._tp.getSlotStackSize(self._side, slot)
  if not count or count == 0 then return nil end
  local key = self._id:identifyAt({ side = self._side, slot = slot })
  if not key then return nil end
  return key, count
end

return { new = new }
