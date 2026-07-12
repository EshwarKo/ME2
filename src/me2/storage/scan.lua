-- me2.storage.scan
--
-- Reconcile: read a storage source slot by slot and return a FRESH index mirroring the
-- world (charter §5: the world is truth; we never trust a stale count over what we see).
-- Empty slots are skipped. Pure over an injected source, so it is proven offline against
-- a fake inventory with zero blocks placed.
--
-- source contract:
--   source:size() -> number of slots
--   source:slotAt(slot) -> key, count      (nil when the slot is empty)

local indexLib = require("me2.storage.index")

local function run(source)
  local n = source:size()
  assert(type(n) == "number", "scan: source:size() must return a number")
  local index = indexLib.new()
  for slot = 1, n do
    local key, count = source:slotAt(slot)
    if key then
      index:setSlot(slot, key, count)
    end
  end
  return index
end

return { run = run }
