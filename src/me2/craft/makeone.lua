-- me2.craft.makeone
--
-- Plan a single craft: resolve a recipe's human-authored item queries to identity keys
-- against what storage currently holds, and decide whether we can afford the inputs.
-- Pure: the decision only reads an index and a resolver; the world-touching feed/poll/collect
-- lives in bin/make.lua. Recipes bind to identity late (charter §5), so resolution happens here.
--
--   resolve(entry) -> { key, ... }   candidate identity keys for a recipe entry (may be empty)
--
-- An entry names an item by oreDict class / label / exact key (see me2.item.resolve). Because
-- one name can map to several real items (GregTech duplicates, tiers), the resolver returns
-- ALL candidates and we pick the one we actually hold the most of -- never guess, never merge.

local M = {}

-- Pick the candidate with the most stock (so we spend a stack that genuinely exists).
-- Returns nil when there are no candidates at all.
local function pick(candidates, index)
  local best, bestCount = nil, -1
  for _, k in ipairs(candidates or {}) do
    local c = index:count(k)
    if c > bestCount then best, bestCount = k, c end
  end
  return best
end

-- Pure: turn a recipe + current index into an actionable plan.
-- Returns { inputs = {{key,item,count},...}, output = {key,item,count}, shortages = {...}, ok }.
-- A shortage is { item, have, need }: either nothing resolves or storage is under-stocked.
function M.plan(recipe, index, resolve)
  assert(recipe and recipe.output, "makeone.plan: recipe needs an output")
  local inputs, shortages = {}, {}
  for _, inp in ipairs(recipe.inputs or {}) do
    local label = inp.ore or inp.item
    local key = pick(resolve(inp), index)
    local have = key and index:count(key) or 0
    if not key or have < inp.count then
      shortages[#shortages + 1] = { item = label, have = have, need = inp.count }
    else
      inputs[#inputs + 1] = { key = key, item = label, count = inp.count }
    end
  end
  local output = {
    key = pick(resolve(recipe.output), index),
    item = recipe.output.ore or recipe.output.item,
    count = recipe.output.count or 1,
  }
  return { inputs = inputs, output = output, shortages = shortages, ok = #shortages == 0 }
end

return M
