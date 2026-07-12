-- Runnable artifact: identify every item in a ROLE's inventory, print keys, persist the
-- registry. Roles bind to hardware via /home/me2/roles.cfg (see me2.hw.roles), so this
-- works across multiple transposers -- e.g. `identify storage` vs `identify craft_output`.
--
-- Usage (OpenComputers shell):
--     identify <role>            e.g.  identify storage
-- Requires the role's transposer with the inventory adjacent, and a Database Upgrade.

package.path = "/home/me2/src/?.lua;/home/me2/src/?/init.lua;" .. package.path

local component = require("component")
local sides = require("sides")
local serialization = require("serialization")
local filesystem = require("filesystem")

local registryLib = require("me2.item.registry")
local identityLib = require("me2.item.identity")
local dbHasherLib = require("me2.adapter.db_hasher")
local rolesLib = require("me2.hw.roles")

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

local args = { ... }
local roleName = args[1] or error("usage: identify <role>  (e.g. storage)")

local bindings = readTable(ROLES_PATH)
assert(bindings, "no roles config at " .. ROLES_PATH
  .. " (run `scan`, then copy config/roles.example.cfg)")
local binding = rolesLib.new(bindings):get(roleName)

assert(component.type(binding.transposer) == "transposer",
  "roles: '" .. roleName .. "' -> " .. binding.transposer .. " is not a transposer")
local transposer = component.proxy(binding.transposer)
local side = sides[binding.side]
assert(type(side) == "number",
  "roles: '" .. roleName .. "' has unknown side '" .. binding.side .. "'")

assert(component.isAvailable("database"), "no database upgrade found (needed for identity)")
local database = component.database

local registry = loadRegistry()
local identity = identityLib.new(dbHasherLib.new(transposer, database), registry)

local size = transposer.getInventorySize(side)
assert(size, "no inventory on " .. binding.side .. " of transposer " .. binding.transposer)

for slot = 1, size do
  local key = identity:identifyAt({ side = side, slot = slot })
  if key then
    local desc = registry:get(key)
    print(string.format("slot %3d  %s  %s", slot, key:sub(1, 12), desc.label or desc.name))
  end
end

saveRegistry(registry)
print(string.format("registry: %d distinct item(s) known -> %s", registry:count(), REG_PATH))
