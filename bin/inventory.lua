-- Phase 1 runnable artifact: scan a storage role and print what you have -- each item's
-- total count and how many slots it occupies -- then persist what we learned about item
-- identities. "Knowing what you have" is the foundation Take and Make build on.
--
-- Usage (OpenComputers shell):
--     inventory [role]           (default role: storage)

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
local scan = require("me2.storage.scan")

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
local roleName = args[1] or "storage"

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
local registry = loadRegistry()
local identity = identityLib.new(dbHasherLib.new(transposer, component.database), registry)
local source = storageSourceLib.new(transposer, identity, side)

local index = scan.run(source)
saveRegistry(registry)

for _, key in ipairs(index:keys()) do
  local desc = registry:get(key)
  local label = desc and (desc.label or desc.name) or key:sub(1, 12)
  local slots = #index:locations(key)
  print(string.format("%7d  %-30s  (%d slot%s)",
    index:count(key), label, slots, slots == 1 and "" or "s"))
end
print(string.format("-- %s: %d distinct item(s), %d total",
  roleName, index:distinctCount(), index:totalItems()))
