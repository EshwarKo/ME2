local keyof = require("me2.item.keyof")

describe("keyof.of", function()
  it("is the same for the same item at different stack sizes", function()
    local a = keyof.of({ name = "iron", damage = 0, size = 1 })
    local b = keyof.of({ name = "iron", damage = 0, size = 64 })
    assert.are.equal(a, b)
  end)

  it("defaults missing damage to 0", function()
    assert.are.equal(keyof.of({ name = "iron" }), keyof.of({ name = "iron", damage = 0 }))
  end)

  it("distinguishes different damage", function()
    assert.are_not.equal(
      keyof.of({ name = "gt.metaitem", damage = 2 }),
      keyof.of({ name = "gt.metaitem", damage = 3 }))
  end)

  it("distinguishes items that carry different NBT tags", function()
    assert.are_not.equal(
      keyof.of({ name = "circuit", damage = 0, hasTag = true, tag = "A" }),
      keyof.of({ name = "circuit", damage = 0, hasTag = true, tag = "B" }))
  end)

  it("treats a tagless item and a tagged item as different", function()
    assert.are_not.equal(
      keyof.of({ name = "circuit", damage = 0 }),
      keyof.of({ name = "circuit", damage = 0, hasTag = true, tag = "A" }))
  end)

  it("fails loud when NBT is present but its bytes are unavailable", function()
    assert.has_error(function()
      keyof.of({ name = "circuit", damage = 0, hasTag = true })
    end)
  end)

  it("errors when the stack has no name", function()
    assert.has_error(function() keyof.of({ damage = 0 }) end)
  end)
end)
