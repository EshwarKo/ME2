local descriptor = require("me2.item.descriptor")

describe("descriptor.fromStack", function()
  it("copies identity-relevant fields and drops size", function()
    local d = descriptor.fromStack({
      name = "gregtech:gt.metaitem.01", label = "Iron Dust",
      damage = 2, maxDamage = 0, size = 42, maxSize = 64, hasTag = false,
    })
    assert.are.equal("gregtech:gt.metaitem.01", d.name)
    assert.are.equal("Iron Dust", d.label)
    assert.are.equal(2, d.damage)
    assert.are.equal(64, d.maxSize)
    assert.is_nil(d.size)
  end)

  it("captures oreNames as a copied array", function()
    local ore = { "plateIron", "plate" }
    local d = descriptor.fromStack({ name = "x", oreNames = ore })
    assert.are.same({ "plateIron", "plate" }, d.oreNames)
    assert.are_not.equal(ore, d.oreNames)
  end)

  it("errors when the stack has no name", function()
    assert.has_error(function() descriptor.fromStack({ label = "x" }) end)
  end)
end)

describe("descriptor.equals", function()
  it("treats stacks that differ only in size as equal", function()
    local a = descriptor.fromStack({ name = "x", damage = 1, size = 1 })
    local b = descriptor.fromStack({ name = "x", damage = 1, size = 64 })
    assert.is_true(descriptor.equals(a, b))
  end)

  it("treats stacks that differ only in label as equal", function()
    local a = descriptor.fromStack({ name = "x", damage = 1, label = "Iron Plate" })
    local b = descriptor.fromStack({ name = "x", damage = 1, label = "Plate of Iron" })
    assert.is_true(descriptor.equals(a, b))
  end)

  it("distinguishes different damage", function()
    local a = descriptor.fromStack({ name = "x", damage = 1 })
    local b = descriptor.fromStack({ name = "x", damage = 2 })
    assert.is_false(descriptor.equals(a, b))
  end)
end)
