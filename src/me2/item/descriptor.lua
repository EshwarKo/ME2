-- me2.item.descriptor
--
-- The identity-relevant, quantity-independent metadata we cache for an item.
-- The canonical identity of an item is its database hash (see me2.item.identity);
-- a descriptor is the set of human/logic-facing facts about the item behind that hash.
-- It deliberately EXCLUDES `size`: how many are in a slot is inventory state, not identity.
--
-- Invariant we rely on everywhere: two stacks with the same identity key yield equal
-- descriptors. Every IDENTITY field below is functionally determined by the item's registry
-- id + damage + NBT (the same inputs that form the key), so this holds by construction.

local descriptor = {}

-- Copied for display/logic. `label` is cosmetic (GregTech drifts it for the same physical
-- item) and `oreNames` is the oreDict class array used for late binding (see me2.item.resolve).
local COPY = { "name", "label", "damage", "maxDamage", "maxSize", "hasTag" }
-- Compared to detect an identity conflict under one key. Excludes `label` (cosmetic, drifts)
-- and `oreNames` (config-gated -- may be present on one read, absent on another).
local IDENTITY = { "name", "damage", "maxDamage", "maxSize", "hasTag" }

-- Build a descriptor from an OpenComputers item-stack table.
function descriptor.fromStack(stack)
  assert(type(stack) == "table", "descriptor.fromStack: stack must be a table")
  assert(type(stack.name) == "string" and stack.name ~= "",
    "descriptor.fromStack: stack has no 'name' (registry id)")
  local d = {}
  for _, f in ipairs(COPY) do
    d[f] = stack[f]
  end
  if type(stack.oreNames) == "table" then
    local ore = {}
    for i, v in ipairs(stack.oreNames) do ore[i] = v end
    d.oreNames = ore
  end
  return d
end

function descriptor.equals(a, b)
  if a == b then return true end
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  for _, f in ipairs(IDENTITY) do
    if a[f] ~= b[f] then return false end
  end
  return true
end

function descriptor.label(d)
  return d.label or d.name
end

return descriptor
