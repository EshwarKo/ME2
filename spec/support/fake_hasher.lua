-- Test double for the identity hasher contract. Maps a location to a canned stack so the
-- identity policy can be proven with zero blocks placed. The key is derived by me2.item.keyof
-- from the stack, exactly as in-game -- the hasher only supplies the stack.

local FakeHasher = {}
FakeHasher.__index = FakeHasher

local function locKey(location)
  return tostring(location.side) .. ":" .. tostring(location.slot)
end

local function new()
  return setmetatable({ _entries = {} }, FakeHasher)
end

function FakeHasher:set(location, stack)
  self._entries[locKey(location)] = stack
  return self
end

function FakeHasher:stackAt(location)
  local stack = self._entries[locKey(location)]
  if not stack then return nil, "fake_hasher: empty at " .. locKey(location) end
  return stack
end

return { new = new }
