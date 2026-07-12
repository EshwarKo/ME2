-- me2.storage.give
--
-- Give out items: decide which storage slots to pull from, then execute the withdrawal
-- through an injected actuator, re-verifying each slot's identity right before it moves.
-- The index is a cache (charter §5); the world may have shifted since the scan, so we never
-- hand out a slot that no longer holds the requested item.
--
-- Split so the decision (plan) is pure and the world-touching part (run) is injected:
--   actuator:keyAt(slot)      -> key | nil     current identity of a source slot
--   actuator:move(slot, count) -> moved         move up to count out; returns actual moved

local M = {}

-- Pure: choose slots to pull from, greedily over locations (already slot-sorted).
-- Returns { moves = {{slot, count}, ...}, taken, short }.
function M.plan(locations, amount)
  assert(type(amount) == "number" and amount >= 0, "give.plan: amount must be >= 0")
  local moves, taken = {}, 0
  for _, loc in ipairs(locations) do
    if taken >= amount then break end
    local take = math.min(loc.count, amount - taken)
    if take > 0 then
      moves[#moves + 1] = { slot = loc.slot, count = take }
      taken = taken + take
    end
  end
  return { moves = moves, taken = taken, short = amount - taken }
end

-- Execute a withdrawal of `amount` of `key` from `index` via `actuator`.
-- Returns { requested, moved, short }. Slots that drifted identity since the scan are skipped.
function M.run(index, key, amount, actuator)
  local plan = M.plan(index:locations(key), amount)
  local moved = 0
  for _, m in ipairs(plan.moves) do
    if actuator:keyAt(m.slot) == key then
      moved = moved + actuator:move(m.slot, m.count)
    end
  end
  return { requested = amount, moved = moved, short = amount - moved }
end

return M
