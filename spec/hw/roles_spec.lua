local rolesLib = require("me2.hw.roles")

local function fixture()
  return rolesLib.new({
    storage     = { transposer = "aaaa", side = "up" },
    craft_input = { transposer = "bbbb", side = "north" },
  })
end

describe("roles", function()
  it("resolves a bound role to transposer + side", function()
    local b = fixture():get("storage")
    assert.are.equal("aaaa", b.transposer)
    assert.are.equal("up", b.side)
  end)

  it("reports membership with has()", function()
    local r = fixture()
    assert.is_true(r:has("craft_input"))
    assert.is_false(r:has("nope"))
  end)

  it("fails loud on an unknown role", function()
    assert.has_error(function() fixture():get("nope") end)
  end)

  it("fails loud on a malformed binding missing the transposer", function()
    local r = rolesLib.new({ bad = { side = "up" } })
    assert.has_error(function() r:get("bad") end)
  end)

  it("fails loud on a malformed binding missing the side", function()
    local r = rolesLib.new({ bad = { transposer = "aaaa" } })
    assert.has_error(function() r:get("bad") end)
  end)

  it("lists bound names sorted", function()
    assert.are.same({ "craft_input", "storage" }, fixture():names())
  end)
end)
