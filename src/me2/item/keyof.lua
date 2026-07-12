-- me2.item.keyof
--
-- Derive an item's canonical identity key from a plain OC stack table. This is THE
-- definition of "the same item" (charter §3): identical registry id, damage, and NBT.
--
-- Why not the database's computeHash? That hash is sha256 over the serialized ItemStack,
-- which includes the stack's Count byte -- so the same item at 1 vs 64 hashes differently,
-- minting phantom duplicate identities. Identity must be quantity-independent, so we build
-- the key ourselves from only the identity-bearing fields:
--
--     name  : registry id            (always present)
--     damage: metadata / subtype     (0 when absent)
--     tag   : raw NBT bytes          (only when the stack carries NBT)
--
-- `tag` is the serialized getTagCompound (item-level NBT), which excludes Count/Damage/id --
-- exactly the NBT that distinguishes otherwise-identical stacks (circuits, cells, tools).
-- It is exposed only when `integration.vanilla.allowItemStackNBTTags=true`; if an item has
-- NBT but the bytes are unavailable we fail loud (charter §5) rather than merge distinct items.

local M = {}

local SEP = "\0"

function M.of(stack)
  assert(type(stack) == "table", "keyof: stack must be a table")
  assert(type(stack.name) == "string" and stack.name ~= "", "keyof: stack has no name")
  local key = stack.name .. SEP .. tostring(stack.damage or 0)
  if stack.hasTag then
    assert(type(stack.tag) == "string" and stack.tag ~= "",
      "keyof: item has NBT but tag bytes unavailable -- enable "
      .. "integration.vanilla.allowItemStackNBTTags")
    key = key .. SEP .. stack.tag
  end
  return key
end

return M
