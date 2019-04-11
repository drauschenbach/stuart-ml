local iterator = require 'stuart-ml.util.java.iterator'

describe('Java Utils :: Scala Iterator', function()

  it('fill() with three elements', function()
    local t = {11,12,13}
    local i = 0
    local f = function()
      i = i + 1
      return t[i]
    end
    local actual = {}
    for v in iterator.fill(#t, f) do
      actual[#actual+1] = v
    end
    local expected = t
    assert.same(expected, actual)
  end)
  
end)
