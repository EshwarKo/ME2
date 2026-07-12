-- Test double for the identity hasher contract. Maps a location to a canned
-- (hash, stack) pair so the identity policy can be proven with zero blocks placed.

local FakeHasher = {}
FakeHasher.__index = FakeHasher

local function locKey(location)
  return tostring(location.side) .. ":" .. tostring(location.slot)
end

local function new()
  return setmetatable({ _entries = {} }, FakeHasher)
end

function FakeHasher:set(location, hash, stack)
  self._entries[locKey(location)] = { hash = hash, stack = stack }
  return self
end

function FakeHasher:hashAt(location)
  local e = self._entries[locKey(location)]
  if not e then return nil, "fake_hasher: empty at " .. locKey(location) end
  return e.hash, e.stack
end

return { new = new }
