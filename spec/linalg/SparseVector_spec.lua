local registerAsserts = require 'registerAsserts'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('linalg.SparseVector', function()

  it('stringifies exactly like Apache Spark', function()
    local indices = {1, 3, 4}
    local values = {0.1, 0.3, 4}
    local vec = Vectors.sparse(3, indices, values)
    local expected = '(3,(1,3,4),(0.1,0.3,4))'
    local actual = tostring(vec)
    assert.equal(expected, actual)
  end)
  
end)
