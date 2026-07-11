-- luacheck config for OpenComputers (OpenOS, Lua 5.3) + busted tests.
std = "lua53"
max_line_length = 100

-- OpenComputers globals available at runtime without an explicit require.
read_globals = {
  "component",
  "computer",
}

-- OpenComputers standard libraries pulled in via require(); listed so luacheck
-- does not flag them as undefined when statically analysed outside the game.
globals = {}

files["spec/**/*.lua"] = {
  std = "+busted",
}

-- OpenOS libraries are loaded with require(); nothing to ignore globally,
-- but allow unused self-documenting args in adapter stubs.
unused_args = false
