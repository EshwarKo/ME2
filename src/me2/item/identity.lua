-- me2.item.identity
--
-- The single place that defines what "the same item" means for the whole system.
-- It turns a physical item location into a canonical identity key and keeps the
-- registry's descriptor cache in step.
--
-- It depends on an injected `hasher` (dependency injection, so this policy is provable
-- offline with zero blocks placed). The hasher's contract is:
--
--     hasher:hashAt(location) -> key:string, stack:table          -- item present
--     hasher:hashAt(location) -> nil, err:string                  -- empty / unreadable
--
-- In-game the hasher is me2.adapter.db_hasher (a Database Upgrade + transposer).
-- In tests it is a fake returning canned (key, stack) pairs (see spec/support/fake_hasher).

local descriptor = require("me2.item.descriptor")

local Identity = {}
Identity.__index = Identity

local function new(hasher, registry)
  assert(hasher, "identity.new: hasher is required")
  assert(registry, "identity.new: registry is required")
  return setmetatable({ _hasher = hasher, _registry = registry }, Identity)
end

-- Identify the item at `location`. Returns its identity key on success, or nil plus an
-- error string if the location holds nothing / cannot be read. On success the registry
-- cache is updated (and will raise if this key ever disagrees about what the item is).
function Identity:identifyAt(location)
  local key, stack = self._hasher:hashAt(location)
  if not key then
    return nil, stack or "identity: empty or unreadable location"
  end
  self._registry:put(key, descriptor.fromStack(stack))
  return key
end

return { new = new }
