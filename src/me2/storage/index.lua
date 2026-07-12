-- me2.storage.index
--
-- The system's picture of one storage inventory: which slot holds what, plus the aggregate
-- "how many of each item do I have, and in how many slots". It is a CACHE of the world
-- (charter §5) -- rebuilt by scanning -- never an authority the world must obey.
--
-- Items are keyed by identity hash (me2.item.identity), so two visually similar but truly
-- distinct stacks never merge. Counts are per slot; totals and locations are derived views
-- kept in step so Take can later ask "how many, and which slots" without a rescan.

local Index = {}
Index.__index = Index

local function new()
  return setmetatable({ _slots = {}, _totals = {}, _byKey = {} }, Index)
end

function Index:clearSlot(slot)
  local cur = self._slots[slot]
  if not cur then return end
  local remaining = self._totals[cur.key] - cur.count
  self._totals[cur.key] = remaining > 0 and remaining or nil
  local locs = self._byKey[cur.key]
  if locs then
    locs[slot] = nil
    if next(locs) == nil then self._byKey[cur.key] = nil end
  end
  self._slots[slot] = nil
end

function Index:setSlot(slot, key, count)
  assert(type(slot) == "number", "index:setSlot: slot must be a number")
  assert(type(key) == "string" and key ~= "", "index:setSlot: key must be a non-empty string")
  assert(type(count) == "number" and count > 0, "index:setSlot: count must be > 0")
  self:clearSlot(slot)
  self._slots[slot] = { key = key, count = count }
  self._totals[key] = (self._totals[key] or 0) + count
  local locs = self._byKey[key]
  if not locs then
    locs = {}
    self._byKey[key] = locs
  end
  locs[slot] = count
end

-- Returns key, count for a slot, or nil if empty.
function Index:slot(slot)
  local cur = self._slots[slot]
  if not cur then return nil end
  return cur.key, cur.count
end

function Index:count(key)
  return self._totals[key] or 0
end

-- List of { slot, count } holding `key`, sorted by slot. Empty when absent.
function Index:locations(key)
  local locs = self._byKey[key]
  if not locs then return {} end
  local out = {}
  for slot, count in pairs(locs) do out[#out + 1] = { slot = slot, count = count } end
  table.sort(out, function(a, b) return a.slot < b.slot end)
  return out
end

function Index:keys()
  local ks = {}
  for k in pairs(self._totals) do ks[#ks + 1] = k end
  table.sort(ks)
  return ks
end

function Index:distinctCount()
  local n = 0
  for _ in pairs(self._totals) do n = n + 1 end
  return n
end

function Index:totalItems()
  local n = 0
  for _, v in pairs(self._totals) do n = n + v end
  return n
end

return { new = new }
