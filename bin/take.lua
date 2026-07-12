-- Phase 2 runnable artifact: give out items. Pull N of an item from a source inventory into
-- a destination inventory, choosing source slots from a fresh storage scan and verifying each
-- slot's identity right before it moves. The first operation that changes the world.
--
-- Usage (OpenComputers shell):
--     take <query> <count> [dest-role] [source-role]
--   query  : an item label/name substring, or an exact identity key
--   count  : how many to give out
--   dest   : destination role (default: craft_output)
--   source : source role (default: storage)

package.path = "/home/me2/src/?.lua;/home/me2/src/?/init.lua;" .. package.path

local component = require("component")
local sides = require("sides")
local serialization = require("serialization")
local filesystem = require("filesystem")

local registryLib = require("me2.item.registry")
local identityLib = require("me2.item.identity")
local dbHasherLib = require("me2.adapter.db_hasher")
local rolesLib = require("me2.hw.roles")
local storageSourceLib = require("me2.adapter.storage_source")
local actuatorLib = require("me2.adapter.actuator")
local scan = require("me2.storage.scan")
local give = require("me2.storage.give")

local ROLES_PATH = "/home/me2/roles.cfg"
local REG_PATH   = "/home/me2/registry.db"

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

-- Resolve a user query to a single identity key present in the index. Exact key wins;
-- otherwise a case-insensitive label/name substring, failing loud on none or ambiguity.
local function resolveKey(index, registry, query)
  if index:count(query) > 0 then return query end
  local q = query:lower()
  local matches = {}
  for _, key in ipairs(index:keys()) do
    local desc = registry:get(key)
    local label = desc and (desc.label or desc.name) or key
    local name = desc and desc.name or ""
    if label:lower():find(q, 1, true) or name:lower():find(q, 1, true) then
      matches[#matches + 1] = { key = key, label = label }
    end
  end
  if #matches == 0 then error("no item matching '" .. query .. "' in storage") end
  if #matches > 1 then
    io.stderr:write("ambiguous '" .. query .. "':\n")
    for _, m in ipairs(matches) do
      io.stderr:write(string.format("  %6d  %s\n", index:count(m.key), m.label))
    end
    error("refine the query")
  end
  return matches[1].key
end

local args = { ... }
local query = args[1] or error("usage: take <query> <count> [dest] [source]")
local count = tonumber(args[2]) or error("count must be a number")
assert(count > 0, "count must be > 0")
local destRole = args[3] or "craft_output"
local sourceRole = args[4] or "storage"

local bindings = readTable(ROLES_PATH)
assert(bindings, "no roles config at " .. ROLES_PATH .. " (run `scan` first)")
local roles = rolesLib.new(bindings)
local src = roles:get(sourceRole)
local dst = roles:get(destRole)
assert(src.transposer == dst.transposer, "reach: '" .. sourceRole .. "' and '" .. destRole
  .. "' are on different transposers; a direct move needs one transposer (buffer comes later)")
assert(component.type(src.transposer) == "transposer",
  "roles: '" .. sourceRole .. "' is not a transposer")

local transposer = component.proxy(src.transposer)
local srcSide = sides[src.side]
local dstSide = sides[dst.side]
assert(type(srcSide) == "number", "roles: bad side for '" .. sourceRole .. "'")
assert(type(dstSide) == "number", "roles: bad side for '" .. destRole .. "'")

assert(component.isAvailable("database"), "no database upgrade found (needed for identity)")
local registry = loadRegistry()
local identity = identityLib.new(dbHasherLib.new(transposer, component.database), registry)

local index = scan.run(storageSourceLib.new(transposer, identity, srcSide))
saveRegistry(registry)

local key = resolveKey(index, registry, query)
local desc = registry:get(key)
local label = desc and (desc.label or desc.name) or key:sub(1, 12)

local actuator = actuatorLib.new(transposer, identity, srcSide, dstSide)
local r = give.run(index, key, count, actuator)

print(string.format("gave %d/%d  %s  ->  %s", r.moved, r.requested, label, destRole))
if r.short > 0 then
  print(string.format("short by %d (had %d in %s)", r.short, index:count(key), sourceRole))
end
