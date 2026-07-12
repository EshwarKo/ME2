-- Phase 3 runnable artifact: make one. Feed a recipe's inputs from storage into the crafter's
-- input, wait for the output to appear and settle, then collect it back into storage. OC never
-- crafts -- it feeds and polls (charter §4). One recipe, no dependency tree yet.
--
-- Usage (OpenComputers shell):
--     make <query> [count]
--   query : an output label/name substring matching a recipe (or exact), ambiguous -> abort
--   count : how many batches to run (default: 1)

package.path = "/home/me2/src/?.lua;/home/me2/src/?/init.lua;" .. package.path

local component = require("component")
local sides = require("sides")
local serialization = require("serialization")
local filesystem = require("filesystem")
local os = require("os")

local registryLib = require("me2.item.registry")
local identityLib = require("me2.item.identity")
local dbHasherLib = require("me2.adapter.db_hasher")
local rolesLib = require("me2.hw.roles")
local storageSourceLib = require("me2.adapter.storage_source")
local actuatorLib = require("me2.adapter.actuator")
local scan = require("me2.storage.scan")
local give = require("me2.storage.give")
local recipesLib = require("me2.craft.recipes")
local makeone = require("me2.craft.makeone")

local ROLES_PATH   = "/home/me2/roles.cfg"
local REG_PATH     = "/home/me2/registry.db"
local RECIPES_PATH = "/home/me2/recipes.cfg"

local POLL    = 2    -- seconds between output polls
local TIMEOUT = 120  -- seconds before we give up waiting for output

local function readTable(path)
  if not filesystem.exists(path) then return nil end
  local f = io.open(path, "r")
  local ok, t = pcall(serialization.unserialize, f:read("*a"))
  f:close()
  if ok and type(t) == "table" then return t end
  return nil
end

local function loadRegistry()
  local t = readTable(REG_PATH)
  return t and registryLib.restore(t) or registryLib.new()
end

local function saveRegistry(reg)
  local f = assert(io.open(REG_PATH, "w"))
  f:write(serialization.serialize(reg:snapshot()))
  f:close()
end

-- Resolve a query to a single identity key known to the registry. Exact key wins; otherwise a
-- case-insensitive label/name substring, raising on ambiguity, nil if unknown.
local function makeResolver(registry)
  return function(query)
    if registry:has(query) then return query end
    local q = query:lower()
    local matches = {}
    for _, key in ipairs(registry:keys()) do
      local desc = registry:get(key)
      local label = desc and (desc.label or desc.name) or key
      local name = desc and desc.name or ""
      if label:lower():find(q, 1, true) or name:lower():find(q, 1, true) then
        matches[#matches + 1] = key
      end
    end
    if #matches == 1 then return matches[1] end
    if #matches > 1 then error("ambiguous input query '" .. query .. "'") end
    return nil
  end
end

-- Scan an inventory role into a fresh index (persisting any newly learned identities).
local function scanRole(transposer, identity, side, registry)
  local index = scan.run(storageSourceLib.new(transposer, identity, side))
  saveRegistry(registry)
  return index
end

local args = { ... }
local query = args[1] or error("usage: make <query> [count]")
local batches = tonumber(args[2] or "1") or error("count must be a number")
assert(batches > 0, "count must be > 0")

-- Recipe lookup (fail loud on none / ambiguous).
local recipeList = readTable(RECIPES_PATH)
assert(recipeList, "no recipes config at " .. RECIPES_PATH)
local found = recipesLib.find(recipeList, query)
if #found == 0 then error("no recipe whose output matches '" .. query .. "'") end
if #found > 1 then
  io.stderr:write("ambiguous recipe '" .. query .. "':\n")
  for _, r in ipairs(found) do io.stderr:write("  " .. r.output.item .. "\n") end
  error("refine the query")
end
local recipe = found[1]

-- Roles: storage feeds craft_input; craft_output drains back to storage. All must share one
-- transposer for a direct move (reach; charter §5).
local bindings = readTable(ROLES_PATH)
assert(bindings, "no roles config at " .. ROLES_PATH .. " (run `scan` first)")
local roles = rolesLib.new(bindings)
local storage = roles:get("storage")
local cin = roles:get("craft_input")
local cout = roles:get("craft_output")
assert(storage.transposer == cin.transposer and cin.transposer == cout.transposer,
  "reach: storage/craft_input/craft_output must share one transposer (buffer comes later)")
assert(component.type(storage.transposer) == "transposer", "roles: storage is not a transposer")

local transposer = component.proxy(storage.transposer)
local storageSide = sides[storage.side]
local cinSide = sides[cin.side]
local coutSide = sides[cout.side]
assert(type(storageSide) == "number", "roles: bad side for 'storage'")
assert(type(cinSide) == "number", "roles: bad side for 'craft_input'")
assert(type(coutSide) == "number", "roles: bad side for 'craft_output'")

assert(component.isAvailable("database"), "no database upgrade found (needed for identity)")
local registry = loadRegistry()
local identity = identityLib.new(dbHasherLib.new(transposer, component.database), registry)
local resolve = makeResolver(registry)

-- Baseline: both craft chests must start empty, so a non-empty output later is unambiguously
-- ours and we never mistake leftover inputs for product (fail loud; charter §3).
assert(scanRole(transposer, identity, cinSide, registry):totalItems() == 0,
  "craft_input is not empty -- clear it before making")
assert(scanRole(transposer, identity, coutSide, registry):totalItems() == 0,
  "craft_output is not empty -- clear it before making")

local feeder = actuatorLib.new(transposer, identity, storageSide, cinSide)
local collector = actuatorLib.new(transposer, identity, coutSide, storageSide)

for batch = 1, batches do
  -- Plan against a fresh storage scan.
  local index = scanRole(transposer, identity, storageSide, registry)
  local plan = makeone.plan(recipe, index, resolve)
  if not plan.ok then
    io.stderr:write("cannot make '" .. recipe.output.item .. "': missing inputs\n")
    for _, s in ipairs(plan.shortages) do
      io.stderr:write(string.format("  %s: have %d, need %d\n", s.item, s.have, s.need))
    end
    error("insufficient inputs")
  end

  -- Feed each input; a short move means the world drifted -- stop rather than craft a partial.
  for _, inp in ipairs(plan.inputs) do
    local r = give.run(index, inp.key, inp.count, feeder)
    if r.moved < inp.count then
      error(string.format("failed to feed %s: moved %d/%d", inp.item, r.moved, inp.count))
    end
  end
  print(string.format("[%d/%d] fed inputs for %s, waiting for output...",
    batch, batches, recipe.output.item))

  -- Poll craft_output until it is non-empty and stable across two polls (settled), or time out.
  local waited, prevTotal, outIndex = 0, -1
  while true do
    outIndex = scanRole(transposer, identity, coutSide, registry)
    local total = outIndex:totalItems()
    if total > 0 and total == prevTotal then break end
    prevTotal = total
    if waited >= TIMEOUT then error("timed out waiting for craft output") end
    os.sleep(POLL)
    waited = waited + POLL
  end

  -- Collect everything the crafter produced back into storage.
  local collected = 0
  for _, key in ipairs(outIndex:keys()) do
    local r = give.run(outIndex, key, outIndex:count(key), collector)
    collected = collected + r.moved
  end

  local outKey = plan.output.key
  local gotExpected = outKey and outIndex:count(outKey) > 0
  print(string.format("[%d/%d] collected %d item(s)%s",
    batch, batches, collected, gotExpected and "" or "  (WARNING: expected output not seen)"))
end
