local indexLib = require("me2.storage.index")
local makeone = require("me2.craft.makeone")

-- resolve: map query -> key, or nil if absent
local function resolver(map)
  return function(q) return map[q] end
end

local recipe = {
  output = { item = "Iron Plate", count = 1 },
  inputs = { { item = "Iron Ingot", count = 2 } },
}

describe("makeone.plan", function()
  local resolve = resolver({ ["Iron Ingot"] = "IRON", ["Iron Plate"] = "PLATE" })

  it("plans a craft when inputs are stocked", function()
    local i = indexLib.new()
    i:setSlot(1, "IRON", 5)
    local p = makeone.plan(recipe, i, resolve)
    assert.is_true(p.ok)
    assert.are.same({ { key = "IRON", item = "Iron Ingot", count = 2 } }, p.inputs)
    assert.are.equal("PLATE", p.output.key)
    assert.are.equal(1, p.output.count)
  end)

  it("reports a shortage when under-stocked", function()
    local i = indexLib.new()
    i:setSlot(1, "IRON", 1)
    local p = makeone.plan(recipe, i, resolve)
    assert.is_false(p.ok)
    assert.are.same({ { item = "Iron Ingot", have = 1, need = 2 } }, p.shortages)
  end)

  it("reports a shortage when an input query is unknown", function()
    local i = indexLib.new()
    local p = makeone.plan(recipe, i, resolver({ ["Iron Plate"] = "PLATE" }))
    assert.is_false(p.ok)
    assert.are.equal(1, #p.shortages)
    assert.are.equal(0, p.shortages[1].have)
  end)

  it("defaults output count to 1 when omitted", function()
    local r = { output = { item = "Iron Plate" }, inputs = {} }
    local p = makeone.plan(r, indexLib.new(), resolve)
    assert.are.equal(1, p.output.count)
    assert.is_true(p.ok)
  end)
end)
