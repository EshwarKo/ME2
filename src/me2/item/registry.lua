-- me2.item.registry
--
-- A key -> descriptor cache, where the key is an item's identity hash
-- (see me2.item.identity). This is the system's answer to "what distinct items exist,
-- and what are they?" It is a CACHE, not truth (charter §5): it can always be rebuilt
-- by rescanning the world.
--
-- It refuses to hold two conflicting descriptors under one key. A mismatch means either
-- a hash collision or an identity bug upstream; per "fail loud" (charter §5) we surface
-- it immediately rather than silently corrupt our picture of what an item is.

local descriptor = require("me2.item.descriptor")

local Registry = {}
Registry.__index = Registry

local function new()
  return setmetatable({ _items = {}, _count = 0 }, Registry)
end

function Registry:has(key)
  return self._items[key] ~= nil
end

function Registry:get(key)
  return self._items[key]
end

-- Insert a descriptor. Returns true if newly added, false if it was already present
-- (identical). Raises if `key` already maps to a different descriptor.
function Registry:put(key, desc)
  assert(type(key) == "string" and key ~= "", "registry:put: key must be a non-empty string")
  assert(type(desc) == "table", "registry:put: descriptor must be a table")
  local existing = self._items[key]
  if existing then
    assert(descriptor.equals(existing, desc),
      "registry:put: identity conflict for key " .. key ..
      " (have '" .. descriptor.label(existing) .. "', got '" .. descriptor.label(desc) .. "')")
    return false
  end
  self._items[key] = desc
  self._count = self._count + 1
  return true
end

function Registry:remove(key)
  if self._items[key] == nil then return false end
  self._items[key] = nil
  self._count = self._count - 1
  return true
end

function Registry:count()
  return self._count
end

function Registry:keys()
  local ks = {}
  for k in pairs(self._items) do ks[#ks + 1] = k end
  table.sort(ks)
  return ks
end

-- A plain-table copy suitable for serialization. Disk I/O belongs to the caller (an
-- adapter), so this module stays pure and offline-testable.
function Registry:snapshot()
  local t = {}
  for k, d in pairs(self._items) do
    local copy = {}
    for f, v in pairs(d) do copy[f] = v end
    t[k] = copy
  end
  return t
end

local function restore(t)
  local r = new()
  for k, d in pairs(t or {}) do
    r:put(k, d)
  end
  return r
end

return { new = new, restore = restore }
