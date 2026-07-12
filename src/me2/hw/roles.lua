-- me2.hw.roles
--
-- The late-binding boundary (charter §5: "hardware is a late binding"). This is the ONE
-- place where role names -- "storage", "craft_input", "craft_output" -- map to concrete
-- hardware: a transposer address plus the side that inventory sits on. Nothing else in the
-- system may name a UUID or a side; everything upstream speaks in roles.
--
-- Bindings are plain data (loaded from /home/me2/roles.cfg). This module validates them and
-- answers lookups, failing loud on anything missing or malformed rather than guessing.

local Roles = {}
Roles.__index = Roles

local function new(bindings)
  assert(type(bindings) == "table", "roles.new: bindings must be a table")
  return setmetatable({ _b = bindings }, Roles)
end

function Roles:has(role)
  return self._b[role] ~= nil
end

-- Resolve a role to { transposer = <address>, side = <name> }. Raises if unbound/malformed.
function Roles:get(role)
  local b = self._b[role]
  assert(b, "roles: no binding for role '" .. tostring(role) .. "'")
  assert(type(b.transposer) == "string" and b.transposer ~= "",
    "roles: role '" .. role .. "' is missing a transposer address")
  assert(type(b.side) == "string" and b.side ~= "",
    "roles: role '" .. role .. "' is missing a side name")
  return { transposer = b.transposer, side = b.side }
end

function Roles:names()
  local ns = {}
  for k in pairs(self._b) do ns[#ns + 1] = k end
  table.sort(ns)
  return ns
end

return { new = new }
