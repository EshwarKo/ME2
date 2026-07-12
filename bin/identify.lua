-- Phase 0 runnable artifact.
--
-- Scan an adjacent inventory, print each occupied slot's identity key + label, and
-- persist the item registry to disk. This proves the identity layer end to end on real
-- hardware: knowing exactly what you have is the foundation every later phase stands on.
--
-- Usage (OpenComputers shell):
--     identify <side>            e.g.  identify north
-- Requires a transposer with the target inventory adjacent, and a Database Upgrade.

package.path = "/home/me2/src/?.lua;/home/me2/src/?/init.lua;" .. package.path

local component = require("component")
local sides = require("sides")
local serialization = require("serialization")
local filesystem = require("filesystem")

local registryLib = require("me2.item.registry")
local identityLib = require("me2.item.identity")
local dbHasherLib = require("me2.adapter.db_hasher")

local REG_PATH = "/home/me2/registry.db"

local function loadRegistry()
  if not filesystem.exists(REG_PATH) then return registryLib.new() end
  local f = io.open(REG_PATH, "r")
  local ok, t = pcall(serialization.unserialize, f:read("*a"))
  f:close()
  if ok and type(t) == "table" then return registryLib.restore(t) end
  return registryLib.new()
end

local function saveRegistry(reg)
  local f = assert(io.open(REG_PATH, "w"))
  f:write(serialization.serialize(reg:snapshot()))
  f:close()
end

local args = { ... }
local sideName = args[1] or "north"
local side = sides[sideName]
assert(side, "unknown side '" .. tostring(sideName) .. "' (try north/south/east/west/up/down)")

local transposer = component.transposer
local database = component.database

local registry = loadRegistry()
local identity = identityLib.new(dbHasherLib.new(transposer, database), registry)

local size = transposer.getInventorySize(side)
assert(size, "no inventory on side " .. sideName)

for slot = 1, size do
  local key = identity:identifyAt({ side = side, slot = slot })
  if key then
    local desc = registry:get(key)
    print(string.format("slot %3d  %s  %s", slot, key:sub(1, 12), desc.label or desc.name))
  end
end

saveRegistry(registry)
print(string.format("registry: %d distinct item(s) known -> %s", registry:count(), REG_PATH))
