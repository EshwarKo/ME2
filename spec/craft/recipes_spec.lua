local recipes = require("me2.craft.recipes")

local list = {
  { output = { item = "Iron Plate", count = 1 }, inputs = { { item = "Iron Ingot", count = 1 } } },
  { output = { item = "Iron Rod", count = 1 }, inputs = { { item = "Iron Ingot", count = 1 } } },
  { output = { item = "Gold Plate", count = 1 }, inputs = { { item = "Gold Ingot", count = 1 } } },
}

describe("recipes.find", function()
  it("matches an exact output name", function()
    local f = recipes.find(list, "Iron Plate")
    assert.are.equal(1, #f)
    assert.are.equal("Iron Plate", f[1].output.item)
  end)

  it("matches case-insensitive substrings", function()
    local f = recipes.find(list, "iron")
    assert.are.equal(2, #f)
  end)

  it("returns empty when nothing matches", function()
    assert.are.same({}, recipes.find(list, "diamond"))
  end)

  it("prefers exact matches even when they are also substrings", function()
    local f = recipes.find(list, "Gold Plate")
    assert.are.equal(1, #f)
    assert.are.equal("Gold Plate", f[1].output.item)
  end)
end)
