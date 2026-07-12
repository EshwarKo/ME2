-- me2.craft.recipes
--
-- A recipe is plain data:
--   { output = { item = <query>, count = n }, inputs = { { item = <query>, count = n }, ... } }
--
-- Item references are human-authored queries (a label/name), resolved to identity keys at
-- make time against the registry. Humans don't write hashes, so recipes bind to identity
-- late (charter §5) -- which keeps them readable and independent of any particular world.

local M = {}

local function matchesOutput(recipe, query)
  local out = recipe.output and recipe.output.item
  if not out then return false end
  if out == query then return true end
  return out:lower():find(query:lower(), 1, true) ~= nil
end

-- Every recipe whose output matches the query (exact, else case-insensitive substring).
function M.find(list, query)
  local found = {}
  for _, r in ipairs(list) do
    if matchesOutput(r, query) then found[#found + 1] = r end
  end
  return found
end

return M
