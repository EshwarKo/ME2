-- me2.item.descriptor
--
-- The identity-relevant, quantity-independent metadata we cache for an item.
-- The canonical identity of an item is its database hash (see me2.item.identity);
-- a descriptor is the set of human/logic-facing facts about the item behind that hash.
-- It deliberately EXCLUDES `size`: how many are in a slot is inventory state, not identity.
--
-- Invariant we rely on everywhere: two stacks with the same hash yield equal descriptors.
-- Every field below is functionally determined by the item's registry id + damage + NBT,
-- all of which feed the hash, so this invariant holds by construction.

local descriptor = {}

local FIELDS = { "name", "label", "damage", "maxDamage", "maxSize", "hasTag" }

-- Build a descriptor from an OpenComputers item-stack table.
function descriptor.fromStack(stack)
  assert(type(stack) == "table", "descriptor.fromStack: stack must be a table")
  assert(type(stack.name) == "string" and stack.name ~= "",
    "descriptor.fromStack: stack has no 'name' (registry id)")
  local d = {}
  for _, f in ipairs(FIELDS) do
    d[f] = stack[f]
  end
  return d
end

function descriptor.equals(a, b)
  if a == b then return true end
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  for _, f in ipairs(FIELDS) do
    if a[f] ~= b[f] then return false end
  end
  return true
end

function descriptor.label(d)
  return d.label or d.name
end

return descriptor
