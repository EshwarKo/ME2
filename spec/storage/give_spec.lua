local indexLib = require("me2.storage.index")
local give = require("me2.storage.give")

-- slotKeys: { [slot] = key }   moveResults (optional): { [slot] = actualMoved }
local function fakeActuator(slotKeys, moveResults)
  return {
    keyAt = function(_, slot) return slotKeys[slot] end,
    move = function(_, slot, count)
      if moveResults and moveResults[slot] ~= nil then return moveResults[slot] end
      return count
    end,
  }
end

describe("give.plan", function()
  local locs = { { slot = 1, count = 5 }, { slot = 3, count = 5 } }

  it("takes from one slot when it suffices", function()
    local p = give.plan(locs, 3)
    assert.are.same({ { slot = 1, count = 3 } }, p.moves)
    assert.are.equal(3, p.taken)
    assert.are.equal(0, p.short)
  end)

  it("spans slots greedily", function()
    local p = give.plan(locs, 7)
    assert.are.same({ { slot = 1, count = 5 }, { slot = 3, count = 2 } }, p.moves)
    assert.are.equal(7, p.taken)
  end)

  it("reports a shortfall when under-stocked", function()
    local p = give.plan(locs, 100)
    assert.are.equal(10, p.taken)
    assert.are.equal(90, p.short)
  end)

  it("zero amount yields no moves", function()
    assert.are.same({}, give.plan(locs, 0).moves)
  end)
end)

describe("give.run", function()
  local function idx()
    local i = indexLib.new()
    i:setSlot(1, "IRON", 5)
    i:setSlot(3, "IRON", 5)
    return i
  end

  it("moves the requested amount when the world agrees", function()
    local r = give.run(idx(), "IRON", 7, fakeActuator({ [1] = "IRON", [3] = "IRON" }))
    assert.are.equal(7, r.moved)
    assert.are.equal(0, r.short)
  end)

  it("skips a slot whose identity drifted since the scan", function()
    local r = give.run(idx(), "IRON", 7, fakeActuator({ [1] = "IRON", [3] = "GOLD" }))
    assert.are.equal(5, r.moved)
    assert.are.equal(2, r.short)
  end)

  it("reflects a partial physical move", function()
    local r = give.run(idx(), "IRON", 5, fakeActuator({ [1] = "IRON", [3] = "IRON" }, { [1] = 2 }))
    assert.are.equal(2, r.moved)
    assert.are.equal(3, r.short)
  end)
end)
