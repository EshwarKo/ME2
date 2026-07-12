local registryLib = require("me2.item.registry")
local resolve = require("me2.item.resolve")

local function registryWith(entries)
  local r = registryLib.new()
  for key, desc in pairs(entries) do r:put(key, desc) end
  return r
end

describe("resolve.candidates", function()
  it("returns an exact key immediately", function()
    local r = registryWith({ K1 = { name = "iron", label = "Iron Plate" } })
    assert.are.same({ "K1" }, resolve.candidates(r, { key = "K1" }))
  end)

  it("matches by oreDict class, ignoring drifted labels", function()
    local r = registryWith({
      A = { name = "gt.a", label = "Iron Plate", oreNames = { "plateIron" } },
      B = { name = "gt.b", label = "Plate (Iron)", oreNames = { "plateIron" } },
      C = { name = "gt.c", label = "Gold Plate", oreNames = { "plateGold" } },
    })
    local got = resolve.candidates(r, { ore = "plateIron" })
    table.sort(got)
    assert.are.same({ "A", "B" }, got)
  end)

  it("prefers the oreDict tier over a label match", function()
    local r = registryWith({
      A = { name = "gt.a", label = "Iron Plate", oreNames = { "plateIron" } },
      B = { name = "gt.b", label = "Iron Plate" },
    })
    assert.are.same({ "A" }, resolve.candidates(r, { ore = "plateIron", item = "Iron Plate" }))
  end)

  it("falls back to an exact label when no oreDict class matches", function()
    local r = registryWith({
      A = { name = "gt.a", label = "Iron Plate" },
      B = { name = "gt.b", label = "Iron Plate Reinforced" },
    })
    assert.are.same({ "A" }, resolve.candidates(r, { item = "Iron Plate" }))
  end)

  it("falls back to a case-insensitive substring", function()
    local r = registryWith({ A = { name = "gt.a", label = "Reinforced Iron Plate" } })
    assert.are.same({ "A" }, resolve.candidates(r, { item = "iron plate" }))
  end)

  it("returns empty when nothing resolves", function()
    local r = registryWith({ A = { name = "gt.a", label = "Gold Plate" } })
    assert.are.same({}, resolve.candidates(r, { ore = "plateIron", item = "Diamond" }))
  end)
end)
