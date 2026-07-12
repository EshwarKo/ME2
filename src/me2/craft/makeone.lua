-- me2.craft.makeone
--
-- Plan a single craft: resolve a recipe's human-authored item queries to identity keys
-- against what storage currently holds, and decide whether we can afford the inputs.
-- Pure: the decision only reads an index and a resolver; the world-touching feed/poll/collect
-- lives in bin/make.lua. Recipes bind to identity late (charter §5), so resolution happens here.
--
--   resolve(query) -> key | nil     identity for a query, or nil if unknown (raises on ambiguity)

local M = {}

-- Pure: turn a recipe + current index into an actionable plan.
-- Returns { inputs = {{key,item,count},...}, output = {key,item,count}, shortages = {...}, ok }.
-- A shortage is { item, have, need }: either the query is unknown or storage is under-stocked.
function M.plan(recipe, index, resolve)
  assert(recipe and recipe.output, "makeone.plan: recipe needs an output")
  local inputs, shortages = {}, {}
  for _, inp in ipairs(recipe.inputs or {}) do
    local key = resolve(inp.item)
    local have = key and index:count(key) or 0
    if not key or have < inp.count then
      shortages[#shortages + 1] = { item = inp.item, have = have, need = inp.count }
    else
      inputs[#inputs + 1] = { key = key, item = inp.item, count = inp.count }
    end
  end
  local output = {
    key = resolve(recipe.output.item),
    item = recipe.output.item,
    count = recipe.output.count or 1,
  }
  return { inputs = inputs, output = output, shortages = shortages, ok = #shortages == 0 }
end

return M
