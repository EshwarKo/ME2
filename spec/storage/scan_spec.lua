local scan = require("me2.storage.scan")

-- A fake scan source: fixed size, plus a map of slot -> { key, count } for occupied slots.
local function fakeSource(size, occupied)
  return {
    size = function() return size end,
    slotAt = function(_, slot)
      local s = occupied[slot]
      if not s then return nil end
      return s.key, s.count
    end,
  }
end

describe("storage.scan", function()
  it("mirrors occupied slots and skips empties", function()
    local src = fakeSource(5, {
      [1] = { key = "A", count = 5 },
      [3] = { key = "A", count = 3 },
      [5] = { key = "B", count = 1 },
    })
    local idx = scan.run(src)
    assert.are.equal(8, idx:count("A"))
    assert.are.equal(1, idx:count("B"))
    assert.are.equal(2, idx:distinctCount())
    assert.are.equal(9, idx:totalItems())
    assert.is_nil((idx:slot(2)))
    local key, count = idx:slot(1)
    assert.are.equal("A", key)
    assert.are.equal(5, count)
  end)

  it("returns an empty index for an empty inventory", function()
    local idx = scan.run(fakeSource(4, {}))
    assert.are.equal(0, idx:distinctCount())
    assert.are.equal(0, idx:totalItems())
  end)
end)
