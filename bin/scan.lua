-- Hardware discovery helper. Lists every transposer and the inventories it can reach,
-- plus the database upgrade, so you can author /home/me2/roles.cfg (role -> transposer+side).
-- Usage:  scan

package.path = "/home/me2/src/?.lua;/home/me2/src/?/init.lua;" .. package.path

local component = require("component")

local SIDE_NAMES = {
  [0] = "down", [1] = "up", [2] = "north", [3] = "south", [4] = "west", [5] = "east",
}

for addr in component.list("transposer") do
  local tp = component.proxy(addr)
  print("transposer " .. addr)
  for side = 0, 5 do
    local size = tp.getInventorySize(side)
    if size then
      local name = tp.getInventoryName and tp.getInventoryName(side) or "?"
      print(string.format("  %-5s (side %d)  %3d slots  %s", SIDE_NAMES[side], side, size, name))
    end
  end
end

if component.isAvailable("database") then
  print("database " .. component.database.address)
else
  print("WARNING: no database upgrade found -- item identity needs one (see CLAUDE.md)")
end
