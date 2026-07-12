-- me2.craft.recipes
--
-- A recipe is plain data:
--   { output = { item|ore = <query>, count = n },
--     inputs = { { item|ore = <query>, count = n }, ... } }
--
-- Item references are human-authored queries: an oreDict class (`ore`, e.g. "plateIron") or a
-- label/name (`item`), resolved to identity keys at make time against the registry. Humans
-- don't write hashes, so recipes bind to identity late (charter §5) -- keeping them readable
-- and independent of any particular world. Prefer `ore` for GregTech (labels drift).

local M = {}

local function matchesOutput(recipe, query)
  local out = recipe.output
  if not out then return false end
  if out.ore and out.ore == query then return true end
  local item = out.item
  if not item then return false end
  if item == query then return true end
  return item:lower():find(query:lower(), 1, true) ~= nil
end

-- Every recipe whose output matches the query (exact ore class or item, else substring).
function M.find(list, query)
  local found = {}
  for _, r in ipairs(list) do
    if matchesOutput(r, query) then found[#found + 1] = r end
  end
  return found
end

return M
