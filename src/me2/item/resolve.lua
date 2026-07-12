-- me2.item.resolve
--
-- Resolve a human-authored recipe entry to candidate identity keys in the registry.
-- Recipes bind to identity late (charter §5): a human writes what they mean, we map it to
-- whatever the world actually holds. An entry may name an item three ways, most to least
-- specific:
--
--     { key = <identity key> }   exact -- already an identity
--     { ore = <oreDict class> }  by oreDict class ("plateIron") -- the robust path
--     { item = <label/name> }    by display label or registry id
--
-- oreDict is preferred for GregTech, whose display labels drift for the same physical item
-- (localization, tier prefixes) while the oreDict class ("plateIron") stays stable. oreNames
-- is only populated when `debug.insertIdsInConverters=true`; if it is empty, `ore` simply
-- finds nothing and the caller reports a shortage (fail loud, no silent wrong match).
--
-- Precedence: the first tier that yields any match wins; all ties within that tier return,
-- and the caller (makeone) picks among them by current stock.
--   1. exact key          2. oreDict class
--   3. exact label/name   4. label/name substring

local M = {}

local function contains(list, want)
  if type(list) ~= "table" then return false end
  for _, v in ipairs(list) do
    if v == want then return true end
  end
  return false
end

-- Candidate identity keys for an entry, best tier first. Returns a (possibly empty) list.
function M.candidates(registry, entry)
  assert(type(entry) == "table", "resolve.candidates: entry must be a table")

  if entry.key and registry:has(entry.key) then
    return { entry.key }
  end

  local keys = registry:keys()

  if entry.ore then
    local out = {}
    for _, k in ipairs(keys) do
      if contains(registry:get(k).oreNames, entry.ore) then out[#out + 1] = k end
    end
    if #out > 0 then return out end
  end

  local q = entry.item
  if not q or q == "" then return {} end
  q = q:lower()

  local exact = {}
  for _, k in ipairs(keys) do
    local d = registry:get(k)
    if (d.label and d.label:lower() == q) or (d.name and d.name:lower() == q) then
      exact[#exact + 1] = k
    end
  end
  if #exact > 0 then return exact end

  local sub = {}
  for _, k in ipairs(keys) do
    local d = registry:get(k)
    if (d.label and d.label:lower():find(q, 1, true))
      or (d.name and d.name:lower():find(q, 1, true)) then
      sub[#sub + 1] = k
    end
  end
  return sub
end

return M
