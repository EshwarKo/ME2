-- me2.adapter.actuator   (IN-GAME ONLY -- not offline-testable by design)
--
-- Moves items out of a source inventory (a transposer side) into a destination inventory
-- (another side of the SAME transposer), and can report a source slot's current identity so
-- the caller (me2.storage.give) can verify before moving. Both roles must share one
-- transposer -- respecting physical reach (charter §5); cross-transposer routing is a later
-- concern needing a shared buffer.
--
--   keyAt(slot)       -> key | nil     identity currently in a source slot
--   move(slot, count) -> moved         move up to count into the destination; actual moved

local Actuator = {}
Actuator.__index = Actuator

local function new(transposer, identity, sourceSide, destSide)
  assert(transposer, "actuator.new: transposer proxy required")
  assert(identity, "actuator.new: identity required")
  assert(type(sourceSide) == "number" and type(destSide) == "number",
    "actuator.new: sides must be numbers")
  return setmetatable({
    _tp = transposer, _id = identity, _src = sourceSide, _dst = destSide,
  }, Actuator)
end

function Actuator:keyAt(slot)
  return self._id:identifyAt({ side = self._src, slot = slot })
end

function Actuator:move(slot, count)
  return self._tp.transferItem(self._src, self._dst, count, slot)
end

return { new = new }
