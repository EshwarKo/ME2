local registryLib = require("me2.item.registry")
local identityLib = require("me2.item.identity")
local keyof = require("me2.item.keyof")
local fakeHasher = require("spec.support.fake_hasher")

describe("identity", function()
  it("returns the derived key and caches the descriptor", function()
    local stack = { name = "iron", label = "Iron Ingot", damage = 0, size = 3 }
    local hasher = fakeHasher.new():set({ side = 2, slot = 1 }, stack)
    local registry = registryLib.new()
    local id = identityLib.new(hasher, registry)

    local key = id:identifyAt({ side = 2, slot = 1 })
    assert.are.equal(keyof.of(stack), key)
    assert.is_true(registry:has(key))
    assert.are.equal("Iron Ingot", registry:get(key).label)
  end)

  it("returns nil plus an error for an empty location", function()
    local id = identityLib.new(fakeHasher.new(), registryLib.new())
    local key, err = id:identifyAt({ side = 2, slot = 9 })
    assert.is_nil(key)
    assert.is_string(err)
  end)

  it("gives the same key for the same item regardless of stack size", function()
    local hasher = fakeHasher.new()
    hasher:set({ side = 2, slot = 1 }, { name = "iron", label = "Iron", damage = 0, size = 1 })
    hasher:set({ side = 2, slot = 2 }, { name = "iron", label = "Iron", damage = 0, size = 64 })
    local registry = registryLib.new()
    local id = identityLib.new(hasher, registry)
    assert.are.equal(id:identifyAt({ side = 2, slot = 1 }),
      id:identifyAt({ side = 2, slot = 2 }))
    assert.are.equal(1, registry:count())
  end)

  it("separates items that differ by NBT tag", function()
    local hasher = fakeHasher.new()
    hasher:set({ side = 2, slot = 1 },
      { name = "circuit", damage = 0, hasTag = true, tag = "nbtA" })
    hasher:set({ side = 2, slot = 2 },
      { name = "circuit", damage = 0, hasTag = true, tag = "nbtB" })
    local registry = registryLib.new()
    local id = identityLib.new(hasher, registry)
    assert.are_not.equal(id:identifyAt({ side = 2, slot = 1 }),
      id:identifyAt({ side = 2, slot = 2 }))
    assert.are.equal(2, registry:count())
  end)

  it("fails loud when one key maps to conflicting descriptors", function()
    local hasher = fakeHasher.new()
    hasher:set({ side = 2, slot = 1 }, { name = "iron", damage = 0, maxSize = 1 })
    hasher:set({ side = 2, slot = 2 }, { name = "iron", damage = 0, maxSize = 64 })
    local id = identityLib.new(hasher, registryLib.new())
    id:identifyAt({ side = 2, slot = 1 })
    assert.has_error(function() id:identifyAt({ side = 2, slot = 2 }) end)
  end)
end)
