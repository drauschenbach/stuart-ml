local registerAsserts = require 'registerAsserts'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('linalg.DenseVector', function()

  it('stringifies sort of like Apache Spark, but in a Lua way', function()
    local vec = Vectors.dense({0.1, 0.3, 4})
    local expected = '(0.1,0.3,4)'
    local actual = tostring(vec)
    assert.equal(expected, actual)
  end)
  
end)
